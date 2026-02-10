provider "kubernetes" {
  host                   = var.endpoint
  cluster_ca_certificate = var.cluster_ca_certificate
  client_certificate     = var.client_certificate
  client_key             = var.client_key
}

provider "helm" {
  kubernetes = {
    host                   = var.endpoint
    cluster_ca_certificate = var.cluster_ca_certificate
    client_certificate     = var.client_certificate
    client_key             = var.client_key
  }
}

# ============================================================================
# Install ArgoCD with GitOps enabled
# ArgoCD CRDs are in the chart's crds/ directory, installed before templates.
# Application CRs only use argoproj.io/v1alpha1 (ArgoCD's own CRD), so
# template rendering succeeds even on a fresh cluster.
# ============================================================================
resource "helm_release" "argocd" {
  name      = "argocd"
  namespace = kubernetes_namespace.argocd.metadata[0].name
  chart     = "${var.helm_values_dir}/argocd"
  wait      = true
  timeout   = 600

  values = [
    file("${var.helm_values_dir}/ports.yaml"),
    file("${var.helm_values_dir}/argocd/values.yaml"),
    file("${var.helm_values_dir}/argocd/values-argocd.yaml"),
    yamlencode({
      transitVaultIP = var.vault_cluster_ip
      gitops = {
        enabled = true
        repoURL = var.git_repo_url
      }
      vaultSecrets = {
        enabled = false
      }
    }),
  ]

  depends_on = [
    kubernetes_secret_v1.argocd_repo_creds,
    kubernetes_secret_v1.argocd_oidc,
    kubernetes_secret_v1.vault_transit_token,
    kubernetes_secret_v1.argocd_redis,
  ]
}
