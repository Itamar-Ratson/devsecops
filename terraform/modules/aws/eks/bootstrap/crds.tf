# ============================================================================
# Gateway API CRDs (experimental channel for Cilium)
# ============================================================================
resource "null_resource" "gateway_api_crds" {
  triggers = {
    version = var.gateway_api_version
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig.filename
    }
    command = <<-EOT
      set -e
      kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_version}/experimental-install.yaml
      kubectl wait --for=condition=Established --timeout=60s crd/gateways.gateway.networking.k8s.io
      kubectl wait --for=condition=Established --timeout=60s crd/httproutes.gateway.networking.k8s.io
      kubectl wait --for=condition=Established --timeout=60s crd/gatewayclasses.gateway.networking.k8s.io
    EOT
  }
}

# ============================================================================
# Prometheus Operator CRDs
# ============================================================================
resource "null_resource" "prometheus_operator_crds" {
  triggers = {
    version = var.prometheus_operator_version
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig.filename
    }
    command = <<-EOT
      set -e
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${var.prometheus_operator_version}/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${var.prometheus_operator_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${var.prometheus_operator_version}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${var.prometheus_operator_version}/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${var.prometheus_operator_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
      kubectl wait --for=condition=Established --timeout=60s crd/servicemonitors.monitoring.coreos.com
    EOT
  }
}
