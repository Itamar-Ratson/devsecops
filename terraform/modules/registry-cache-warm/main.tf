# Push images from KinD node containerd stores into the Zot registry cache.
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
      set -euo pipefail
      NODE=$(kind get nodes --name ${var.cluster_name} | head -1)
      echo "Warming cache from node: $NODE → ${var.cache_cluster_ip}:5000"

      for registry in docker.io ghcr.io quay.io registry.k8s.io; do
        docker exec "$NODE" ctr -n k8s.io images ls -q \
          | grep "^$registry/" \
          | grep -v '@sha256:' \
          | sort -u \
          | while read -r img; do
              path=$(echo "$img" | sed "s|^$registry/||")
              dest="${var.cache_cluster_ip}:5000/$path"
              echo "  $img → $dest"
              docker exec "$NODE" ctr -n k8s.io images tag --force "$img" "$dest" 2>/dev/null || true
              docker exec "$NODE" ctr -n k8s.io images push --plain-http "$dest" 2>/dev/null || true
            done
      done

      echo "Cache warming complete."
    EOT
  }
}
