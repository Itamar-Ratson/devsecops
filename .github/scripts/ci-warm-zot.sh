#!/usr/bin/env bash
# Warm Zot cache from GHCR mirror.
# Inverse of ci-save-images.sh: pulls cached images from GHCR into local Zot
# so containerd mirror config serves them on cache hit.
#
# Uses gh api to discover packages (GHCR doesn't support crane catalog).
set -euo pipefail

OWNER="${GITHUB_REPOSITORY_OWNER:-itamar-ratson}"
MIRROR_PREFIX="devsecops/mirror/"
ZOT="${ZOT:-localhost:5050}"

# List all mirror packages via GitHub API
# /user/packages requires a user token; GITHUB_TOKEN is a repo installation
# token, so use /users/{owner}/packages instead.
PACKAGES=$(gh api "/users/${OWNER}/packages?package_type=container&per_page=100" -q '.[].name' \
  | grep "^${MIRROR_PREFIX}" || true)

if [ -z "$PACKAGES" ]; then
  echo "No cached images in GHCR yet (first run). Skipping warm."
  exit 0
fi

echo "Warming Zot from GHCR cache..."
COUNT=0
for pkg in $PACKAGES; do
  # pkg = "devsecops/mirror/library/nginx" -> image path = "library/nginx"
  img_path="${pkg#"${MIRROR_PREFIX}"}"
  GHCR_REF="ghcr.io/${OWNER}/${pkg}"

  for tag in $(crane ls "$GHCR_REF" 2>/dev/null); do
    echo "  $GHCR_REF:$tag -> $ZOT/$img_path:$tag"
    if crane copy --insecure "$GHCR_REF:$tag" "$ZOT/$img_path:$tag" 2>/dev/null; then
      COUNT=$((COUNT + 1))
    else
      echo "    Warning: failed to cache $img_path:$tag"
    fi
  done
done
echo "Zot warm complete. $COUNT images loaded."
