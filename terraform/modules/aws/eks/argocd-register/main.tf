# Provider targets KinD cluster (where ArgoCD runs)
provider "kubernetes" {
  host                   = var.kind_endpoint
  cluster_ca_certificate = var.kind_cluster_ca_certificate
  client_certificate     = var.kind_client_certificate
  client_key             = var.kind_client_key
}

# ============================================================================
# Register EKS as a remote cluster in ArgoCD
# ============================================================================

resource "kubernetes_secret_v1" "eks_cluster" {
  metadata {
    name      = "eks-cluster"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }

  data = {
    name   = var.eks_cluster_name
    server = var.eks_cluster_endpoint
    config = jsonencode({
      bearerToken = var.argocd_manager_token
      tlsClientConfig = {
        caData   = var.eks_cluster_ca_data
        insecure = false
      }
    })
  }
}

# ============================================================================
# EKS root Application — syncs helm/argo/eks-apps
# ============================================================================

resource "kubernetes_manifest" "eks_apps" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = "eks-apps"
      namespace  = "argocd"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = "HEAD"
        path           = "helm/argo/eks-apps"
        helm = {
          valueFiles = ["values.yaml"]
          valuesObject = {
            repoURL          = var.git_repo_url
            eksClusterServer = var.eks_cluster_endpoint
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

  depends_on = [kubernetes_secret_v1.eks_cluster]
}

# Strip ArgoCD Application finalizer before destroy to prevent hang
# if the EKS cluster is already unreachable.
resource "terraform_data" "strip_eks_app_finalizer" {
  depends_on = [kubernetes_manifest.eks_apps]

  input = "eks-apps"

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl patch application eks-apps -n argocd --context kind-on-prem --type merge -p '{\"metadata\":{\"finalizers\":null}}' 2>/dev/null || true"
  }
}
