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
    command = "kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_version}/experimental-install.yaml"
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
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${var.prometheus_operator_version}/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${var.prometheus_operator_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${var.prometheus_operator_version}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${var.prometheus_operator_version}/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${var.prometheus_operator_version}/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
    EOT
  }
}

# ============================================================================
# cert-manager CRDs
# ============================================================================
resource "null_resource" "cert_manager_crds" {
  triggers = {
    version = var.cert_manager_version
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig.filename
    }
    command = "kubectl apply --server-side -f https://github.com/cert-manager/cert-manager/releases/download/${var.cert_manager_version}/cert-manager.crds.yaml"
  }
}
