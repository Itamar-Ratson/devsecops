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
# Uses GH_TOKEN (PAT with read:packages + delete:packages) set by the workflow.
echo "Cleaning stale images from GHCR..."
OWNER="${GITHUB_REPOSITORY_OWNER}"
MIRROR_PREFIX="devsecops/mirror/"

PACKAGES=$(gh api "/users/${OWNER}/packages?package_type=container&per_page=100" -q '.[].name')
MIRROR_PKGS=$(echo "$PACKAGES" | grep "^${MIRROR_PREFIX}" || true)

if [ -z "$MIRROR_PKGS" ]; then
  echo "  No mirror packages found."
else
  echo "$MIRROR_PKGS" | while read -r pkg; do
    local_path="${pkg#"${MIRROR_PREFIX}"}"
    if ! grep -qF "$local_path" "$PUSHED_FILE" 2>/dev/null; then
      echo "  Deleting stale package: $pkg"
      encoded=$(printf '%s' "$pkg" | jq -sRr @uri)
      gh api -X DELETE "/users/${OWNER}/packages/container/${encoded}"
    fi
  done
fi

rm -f "$PUSHED_FILE"
echo "Cleanup complete."
