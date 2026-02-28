# ============================================================================
# Cilium CNI — installed BEFORE node group so nodes become Ready immediately
# ============================================================================
resource "helm_release" "cilium" {
  name          = "cilium"
  namespace     = "kube-system"
  chart         = "${var.helm_values_dir}/networking/cilium"
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  values = [
    file("${var.helm_values_dir}/ports.yaml"),
    file("${var.helm_values_dir}/networking/cilium/values-eks.yaml"),
  ]

  # EKS API endpoint — Cilium needs this to reach the API server during bootstrap
  # because kube-proxy is not installed (Cilium replaces it).
  set = [
    {
      name  = "cilium.k8sServiceHost"
      value = trimprefix(module.eks.cluster_endpoint, "https://")
    },
    {
      name  = "cilium.k8sServicePort"
      value = "443"
    },
  ]

  depends_on = [null_resource.gateway_api_crds, null_resource.prometheus_operator_crds]

  # ArgoCD adopts this release after bootstrap and owns all day-2 changes.
  # Terraform only creates and destroys — never updates.
  lifecycle {
    ignore_changes = all
  }
}
