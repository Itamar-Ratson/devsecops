# Cluster infrastructure installed after Cilium + nodes are ready:
# - Gateway API CRDs (required by Cilium GatewayClass/HTTPRoute)
# - local-path-provisioner (Talos has no default StorageClass)

resource "null_resource" "gateway_api_crds" {
  depends_on = [null_resource.wait_nodes]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Installing Gateway API CRDs v1.2.1..."
      kubectl --kubeconfig=${local_sensitive_file.kubeconfig.filename} apply -f \
        https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml
      echo "Gateway API CRDs installed successfully"
    EOT
  }
}

resource "null_resource" "local_path_provisioner" {
  depends_on = [null_resource.wait_nodes]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      KUBECONFIG=${local_sensitive_file.kubeconfig.filename}

      echo "Installing local-path-provisioner v0.0.30..."
      kubectl --kubeconfig=$KUBECONFIG apply -f \
        https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml

      echo "Waiting for local-path-provisioner deployment..."
      kubectl --kubeconfig=$KUBECONFIG -n local-path-storage rollout status deployment/local-path-provisioner --timeout=120s

      echo "Patching config for Talos writable path (/var/local-path-provisioner)..."
      kubectl --kubeconfig=$KUBECONFIG -n local-path-storage get configmap local-path-config -o json \
        | jq '.data["config.json"] = (.data["config.json"] | fromjson | .nodePathMap[0].paths = ["/var/local-path-provisioner"] | tojson)' \
        | kubectl --kubeconfig=$KUBECONFIG apply -f -

      echo "Labeling namespace for privileged PodSecurity (helper pods need hostPath)..."
      kubectl --kubeconfig=$KUBECONFIG label namespace local-path-storage \
        pod-security.kubernetes.io/enforce=privileged --overwrite

      echo "Setting local-path as default StorageClass..."
      kubectl --kubeconfig=$KUBECONFIG patch storageclass local-path \
        -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

      echo "Restarting local-path-provisioner to pick up config change..."
      kubectl --kubeconfig=$KUBECONFIG -n local-path-storage rollout restart deployment/local-path-provisioner
      kubectl --kubeconfig=$KUBECONFIG -n local-path-storage rollout status deployment/local-path-provisioner --timeout=120s

      echo "local-path-provisioner installed and configured successfully"
    EOT
  }
}
