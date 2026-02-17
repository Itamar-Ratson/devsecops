#!/usr/bin/env bash
# Save CI images to GHCR for caching across runs, then clean stale images.
# Reuses the same collection logic as terraform/modules/registry/warm/main.tf
# but targets GHCR instead of localhost Zot.
set -euo pipefail

GHCR_REPO="${GHCR_REPO:-ghcr.io/itamar-ratson/devsecops/mirror}"
CLUSTER_NAME="${CLUSTER_NAME:-on-prem}"
PUSHED_FILE=$(mktemp)

# --- Phase 1: Collect and push ---
echo "Collecting images from KinD nodes..."
IMAGES=""
for NODE in $(kind get nodes --name "$CLUSTER_NAME"); do
  NODE_IMAGES=$(docker exec "$NODE" ctr -n k8s.io images ls -q \
    | grep -v '@sha256:' \
    | grep -v '^172\.')
  IMAGES="$IMAGES
$NODE_IMAGES"
done
IMAGES=$(echo "$IMAGES" | sort -u | sed '/^$/d')

for img in $IMAGES; do
  case "$img" in
    docker.io/*)       path=${img#docker.io/}       ;;
    ghcr.io/*)         path=${img#ghcr.io/}         ;;
    quay.io/*)         path=${img#quay.io/}         ;;
    registry.k8s.io/*) path=${img#registry.k8s.io/} ;;
    *) continue ;;
  esac

  echo "  $img -> $GHCR_REPO/$path"
  if crane copy --platform linux/amd64 "$img" "$GHCR_REPO/$path" 2>/dev/null; then
    echo "$path" >> "$PUSHED_FILE"
  else
    echo "    Warning: failed to push $img"
  fi
done
echo "Push complete. $(wc -l < "$PUSHED_FILE") images cached."

# --- Phase 2: Clean up stale images ---
echo "Cleaning stale images from GHCR..."
MIRROR_PREFIX="devsecops/mirror/"

gh api "/user/packages?package_type=container&per_page=100" --paginate -q '.[].name' \
  | grep "^${MIRROR_PREFIX}" | while read -r pkg; do
    # pkg = "devsecops/mirror/argoproj/argo-rollouts"
    local_path="${pkg#"${MIRROR_PREFIX}"}"
    if ! grep -qF "$local_path" "$PUSHED_FILE" 2>/dev/null; then
      echo "  Deleting stale package: $pkg"
      encoded=$(printf '%s' "$pkg" | jq -sRr @uri)
      gh api -X DELETE "/user/packages/container/${encoded}" 2>/dev/null || true
    fi
done

rm -f "$PUSHED_FILE"
echo "Cleanup complete."
