locals {
  git_url_parts = try(
    regex("git@github\\.com:([^/]+)/([^.]+)(?:\\.git)?$", var.git_repo_url),
    regex("https://github\\.com/([^/]+)/([^/.]+?)(?:\\.git)?$", var.git_repo_url),
  )
  github_owner = local.git_url_parts[0]
  github_repo  = local.git_url_parts[1]
  globals      = yamldecode(file("${var.helm_values_dir}/globals.yaml"))
  domain       = local.globals.cloudflare.domain
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
  depends_on = [helm_release.argocd, kubernetes_manifest.argocd_root_application]

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
  chart     = "${var.helm_values_dir}/argo/cd"
  wait      = true
  timeout   = 600

  values = [
    file("${var.helm_values_dir}/ports.yaml"),
    file("${var.helm_values_dir}/globals.yaml"),
    file("${var.helm_values_dir}/argo/cd/values.yaml"),
    file("${var.helm_values_dir}/argo/cd/values-argocd.yaml"),
    yamlencode({
      transitVaultIP  = var.vault_cluster_ip
      cacheRegistryIP = var.cache_cluster_ip
      vaultSecrets    = { enabled = false }
    }),
  ]

  depends_on = [
    kubernetes_secret_v1.argocd_repo_creds,
    kubernetes_secret_v1.argocd_oidc,
    kubernetes_secret_v1.vault_transit_token,
    kubernetes_secret_v1.argocd_redis,
  ]
}

# ============================================================================
# Phase 2: Root "app-of-apps" Application CR
#
# Created via kubernetes_manifest (uses the existing kubernetes provider —
# no extra provider, no kubeconfig file, no shell heredoc).
# Created OUTSIDE the ArgoCD Helm chart so it is not part of any sync wave.
# ArgoCD picks this up, syncs helm/argo/apps, and creates all child
# Application CRs from templates/applications/.
# This gives GitOps self-management without the wave-0 deadlock.
#
# Destroy ordering: cleanup_app_crs (depends on this) runs its destroy
# provisioner first (kubectl delete all apps), then Terraform removes this
# resource. The Application CR is already gone at that point → 404 is
# handled gracefully by the kubernetes provider.
# ============================================================================
resource "kubernetes_manifest" "argocd_root_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = "argocd"
      namespace  = "argocd"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = "HEAD"
        path           = "helm/argo/apps"
        helm = {
          valueFiles = ["values.yaml", "../../globals.yaml"]
          valuesObject = {
            repoURL         = var.git_repo_url
            transitVaultIP  = var.vault_cluster_ip
            cacheRegistryIP = var.cache_cluster_ip
            applications    = { juiceShop = { enabled = var.juice_shop_enabled } }
          }
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      ignoreDifferences = [
        {
          group = "argoproj.io"
          kind  = "Application"
          jsonPointers = [
            "/operation",
            "/metadata/annotations/argocd.argoproj.io~1refresh",
          ]
        }
      ]
      syncPolicy = {
        automated = {
          prune    = false
          selfHeal = true
        }
        syncOptions = ["ServerSideApply=true", "RespectIgnoreDifferences=true"]
        retry = {
          limit = 30
          backoff = {
            duration    = "30s"
            factor      = 2
            maxDuration = "5m"
          }
        }
      }
    }
  }

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }

  depends_on = [helm_release.argocd]
}
