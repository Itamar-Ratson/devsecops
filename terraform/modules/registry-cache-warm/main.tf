# Copy images from upstream registries into the Zot registry cache.
# Uses crane (via Docker container) to handle multi-arch manifests and
# layer compression correctly.
#
# Waits for all ArgoCD Applications to become Healthy so every image
# used by the cluster is captured.  On the next destroy/apply cycle the
# containerd mirrors (configured in kind-cluster) serve cached layers
# from Zot instead of pulling from the internet.

resource "null_resource" "warm_cache" {
  # Always re-run — this module is invoked on-demand to snapshot current images.
  triggers = {
    run_id = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -uo pipefail

      # --- Wait for ArgoCD applications to be healthy ---
      TIMEOUT=900
      INTERVAL=60
      ELAPSED=0

      echo "Waiting for ArgoCD applications to sync and become healthy..."
      while [ $ELAPSED -lt $TIMEOUT ]; do
        TOTAL=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l)
        HEALTHY=$(kubectl get applications -n argocd \
          -o jsonpath='{range .items[*]}{.status.health.status}{"\n"}{end}' 2>/dev/null \
          | grep -c "^Healthy$" || true)

        if [ "$TOTAL" -gt 0 ] && [ "$HEALTHY" -eq "$TOTAL" ]; then
          echo "All $TOTAL ArgoCD applications are healthy."
          break
        fi

        echo "  $HEALTHY/$TOTAL healthy, waiting... ($${ELAPSED}s/${TIMEOUT}s)"
        sleep $INTERVAL
        ELAPSED=$((ELAPSED + INTERVAL))
      done

      if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "Warning: Timed out after $${TIMEOUT}s. Proceeding with currently pulled images."
      fi

      # --- Copy images into Zot ---
      NODE=$(kind get nodes --name ${var.cluster_name} | head -1)
      DEST="localhost:${var.cache_host_port}"
      CRANE="docker run --rm --network host gcr.io/go-containerregistry/crane"

      echo "Warming cache: images from $NODE → $DEST"

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
