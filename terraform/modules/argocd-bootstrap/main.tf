locals {
  git_url_parts = regex("git@github\\.com:([^/]+)/([^.]+)(?:\\.git)?$", var.git_repo_url)
  github_owner  = local.git_url_parts[0]
  github_repo   = local.git_url_parts[1]
}

provider "github" {
  owner = local.github_owner
  token = var.github_token
}

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
# Strip ArgoCD Application finalizers before helm uninstall.
# Without this, helm uninstall hangs forever — the finalizer controller
# (ArgoCD itself) gets killed mid-delete and can't process the finalizers.
# ============================================================================
resource "terraform_data" "argocd_finalizer_cleanup" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # 1. Strip finalizers from all ArgoCD Applications
      kubectl get applications.argoproj.io -n argocd -o name 2>/dev/null | \
        xargs -I{} kubectl patch {} -n argocd --type json \
          -p '[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true

      # 2. Delete all Application CRs so helm doesn't wait for them
      kubectl delete applications.argoproj.io --all -n argocd --wait=false 2>/dev/null || true

      # 3. Remove ArgoCD webhook configurations that block API server deletions
      kubectl delete validatingwebhookconfigurations -l app.kubernetes.io/part-of=argocd 2>/dev/null || true
      kubectl delete mutatingwebhookconfigurations -l app.kubernetes.io/part-of=argocd 2>/dev/null || true

      # 4. Scale down ArgoCD to stop reconciliation during teardown
      kubectl scale deploy --all -n argocd --replicas=0 --timeout=30s 2>/dev/null || true
      kubectl delete pods -n argocd --all --force --grace-period=0 2>/dev/null || true
    EOT
  }
}

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
