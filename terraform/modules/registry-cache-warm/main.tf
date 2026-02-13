# Copy images from upstream registries into the Zot registry cache.
# Uses crane (via Docker container) to handle multi-arch manifests and
# layer compression correctly.
#
# Designed to run after ArgoCD has synced all applications so every image
# used by the cluster is captured.  On the next destroy/apply cycle the
# containerd mirrors (configured in kind-cluster) serve cached layers from
# Zot instead of pulling from the internet.
#
# Run:  cd terraform/live/registry-cache-warm && terragrunt apply --non-interactive
# Exclude from full deploy:  --terragrunt-exclude-dir registry-cache-warm

resource "null_resource" "warm_cache" {
  # Always re-run — this module is invoked on-demand to snapshot current images.
  triggers = {
    run_id = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -uo pipefail

      NODE=$(kind get nodes --name ${var.cluster_name} | head -1)
      DEST="localhost:${var.cache_host_port}"
      CRANE="docker run --rm --network host gcr.io/go-containerregistry/crane"

      echo "Warming cache: images from $NODE → $DEST"

      # Collect unique tagged images from the KinD node
      IMAGES=$(docker exec "$NODE" ctr -n k8s.io images ls -q \
        | grep -v '@sha256:' \
        | grep -v '^172\.' \
        | sort -u)

      for img in $IMAGES; do
        case "$img" in
          docker.io/*)       path=$${img#docker.io/}       ;;
          ghcr.io/*)         path=$${img#ghcr.io/}         ;;
          quay.io/*)         path=$${img#quay.io/}         ;;
          registry.k8s.io/*) path=$${img#registry.k8s.io/} ;;
          *) continue ;;
        esac

        echo "  $img → $DEST/$path"
        $CRANE copy --platform linux/amd64 "$img" "$DEST/$path" 2>/dev/null \
          || echo "    Warning: failed to cache $img"
      done

      echo "Cache warming complete."
    EOT
  }
}
