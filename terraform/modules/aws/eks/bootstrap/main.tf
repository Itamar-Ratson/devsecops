provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
  }
}

provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
    }
  }
}

provider "kubectl" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
  }
  load_config_file = false
}

# ============================================================================
# ArgoCD remote cluster SA — long-lived token for ArgoCD on KinD
# ============================================================================

resource "kubernetes_service_account_v1" "argocd_manager" {
  metadata {
    name      = "argocd-manager"
    namespace = "kube-system"
  }
}

resource "kubernetes_secret_v1" "argocd_manager_token" {
  metadata {
    name      = "argocd-manager-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.argocd_manager.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

# Scoped ClusterRole for ArgoCD — not cluster-admin.
# Grants the minimum permissions ArgoCD needs to manage workloads.
resource "kubernetes_cluster_role_v1" "argocd_manager" {
  metadata {
    name = "argocd-manager"
  }

  # ArgoCD needs to list/watch/create/update/delete workload resources
  rule {
    api_groups = ["", "apps", "batch", "networking.k8s.io", "rbac.authorization.k8s.io", "policy"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # ArgoCD Application CRDs and Cilium CRDs
  rule {
    api_groups = ["argoproj.io", "cilium.io", "gateway.networking.k8s.io", "external-secrets.io", "monitoring.coreos.com", "cert-manager.io"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # ArgoCD needs to read cluster state
  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "argocd_manager" {
  metadata {
    name = "argocd-manager"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.argocd_manager.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.argocd_manager.metadata[0].name
    namespace = "kube-system"
  }
}
