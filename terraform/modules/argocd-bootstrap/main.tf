locals {
  kubeconfig = yamldecode(var.kubeconfig)
}

provider "kubernetes" {
  host                   = local.kubeconfig.clusters[0].cluster.server
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
  client_certificate     = base64decode(local.kubeconfig.users[0].user["client-certificate-data"])
  client_key             = base64decode(local.kubeconfig.users[0].user["client-key-data"])
}

provider "helm" {
  kubernetes = {
    host                   = local.kubeconfig.clusters[0].cluster.server
    cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
    client_certificate     = base64decode(local.kubeconfig.users[0].user["client-certificate-data"])
    client_key             = base64decode(local.kubeconfig.users[0].user["client-key-data"])
  }
}

resource "kubernetes_secret_v1" "argocd_repo_creds" {
  metadata {
    name      = "argocd-repo-creds"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    type          = "git"
    url           = var.git_repo_url
    sshPrivateKey = var.argocd_ssh_private_key
  }
}

# Install ArgoCD core without CRD-dependent resources (Applications, HTTPRoute, ServiceMonitor)
# gitops.enabled=false skips those templates so install succeeds on a fresh cluster
resource "helm_release" "argocd" {
  depends_on = [kubernetes_secret_v1.argocd_repo_creds]

  name      = "argocd"
  chart     = "${var.helm_values_dir}/argocd"
  namespace = "argocd"

  values = [
    file("${var.helm_values_dir}/ports.yaml"),
    file("${var.helm_values_dir}/argocd/values.yaml"),
    file("${var.helm_values_dir}/argocd/values-argocd.yaml")
  ]

  set = [
    {
      name  = "gitops.enabled"
      value = "false"
    }
  ]
}

# Root Application for ArgoCD self-management.
# ArgoCD syncs from git (where gitops.enabled=true), deploying all Applications.
# HTTPRoute/ServiceMonitor will initially be OutOfSync until their CRDs are installed
# by the gateway and monitoring Applications respectively.
resource "kubernetes_manifest" "argocd_root_app" {
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "argocd"
      namespace = "argocd"
      annotations = {
        "argocd.argoproj.io/sync-wave" = "0"
      }
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = "HEAD"
        path           = "helm/argocd"
        helm = {
          valueFiles = ["../ports.yaml", "values.yaml", "values-argocd.yaml"]
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      ignoreDifferences = [
        {
          group        = ""
          kind         = "Secret"
          name         = "argocd-secret"
          jsonPointers = ["/data"]
        },
        {
          group        = "gateway.networking.k8s.io"
          kind         = "HTTPRoute"
          jsonPointers = ["/spec/parentRefs"]
        }
      ]
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "ServerSideApply=true",
          "RespectIgnoreDifferences=true"
        ]
      }
    }
  }
}
