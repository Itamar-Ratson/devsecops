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
# Destroy-time cleanup for ArgoCD.
# Without this, helm uninstall hangs — the finalizer controller (ArgoCD)
# gets killed mid-delete and can't process its own finalizers.
#
# Destroy order (reverse of depends_on):
#   stop_argocd → strip_app_finalizers + strip_job_finalizers + cleanup_webhooks
#   → cleanup_app_crs → helm_release
# ============================================================================

resource "terraform_data" "cleanup_app_crs" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete applications.argoproj.io --all -n argocd --wait=false 2>/dev/null || true"
  }
}

resource "terraform_data" "strip_app_finalizers" {
  depends_on = [terraform_data.cleanup_app_crs]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl get applications.argoproj.io -n argocd -o name 2>/dev/null | \
        xargs -r -I{} kubectl patch {} -n argocd \
          --type merge -p '{"metadata":{"finalizers":null}}' 2>/dev/null || true
    EOT
  }
}

resource "terraform_data" "strip_job_finalizers" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
        kubectl get jobs -n "$ns" -o jsonpath='{range .items[?(@.metadata.finalizers)]}{.metadata.name}{"\n"}{end}' 2>/dev/null | \
          xargs -r -I{} kubectl patch job {} -n "$ns" \
            --type merge -p '{"metadata":{"finalizers":null}}' 2>/dev/null || true
      done
    EOT
  }
}

resource "terraform_data" "cleanup_webhooks" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl delete validatingwebhookconfigurations -l app.kubernetes.io/part-of=argocd 2>/dev/null || true
      kubectl delete mutatingwebhookconfigurations -l app.kubernetes.io/part-of=argocd 2>/dev/null || true
    EOT
  }
}

resource "terraform_data" "stop_argocd" {
  depends_on = [
    terraform_data.strip_app_finalizers,
    terraform_data.strip_job_finalizers,
    terraform_data.cleanup_webhooks,
  ]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl scale deploy --all -n argocd --replicas=0 --timeout=30s 2>/dev/null || true
      kubectl delete pods -n argocd --all --force --grace-period=0 2>/dev/null || true
    EOT
  }
}

resource "helm_release" "argocd" {
  name      = "argocd"
  namespace = kubernetes_namespace_v1.argocd.metadata[0].name
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
