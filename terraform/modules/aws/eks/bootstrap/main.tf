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
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
    }
  }
}

# Write kubeconfig to disk for kubectl commands in null_resource provisioners
resource "local_sensitive_file" "kubeconfig" {
  content = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      cluster = {
        server                     = var.cluster_endpoint
        certificate-authority-data = var.cluster_ca_data
      }
      name = var.cluster_name
    }]
    contexts = [{
      context = {
        cluster = var.cluster_name
        user    = var.cluster_name
      }
      name = var.cluster_name
    }]
    current-context = var.cluster_name
    users = [{
      name = var.cluster_name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args       = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
        }
      }
    }]
  })
  filename = "/tmp/devsecops-eks-kubeconfig"
}

# ============================================================================
# Cilium CNI
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

  depends_on = [null_resource.gateway_api_crds, null_resource.prometheus_operator_crds]

  # ArgoCD adopts this release after bootstrap and owns all day-2 changes.
  # Terraform only creates and destroys — never updates.
  lifecycle {
    ignore_changes = all
  }
}

# Wait for all nodes to be ready after Cilium installation
resource "null_resource" "wait_nodes_ready" {
  depends_on = [helm_release.cilium]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig.filename
    }
    command = "kubectl wait --for=condition=Ready nodes --all --timeout=300s"
  }
}

# Restart CoreDNS if it was stuck Pending before Cilium provided networking
resource "null_resource" "coredns_restart" {
  depends_on = [null_resource.wait_nodes_ready]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig.filename
    }
    command = "kubectl rollout restart deployment coredns -n kube-system && kubectl rollout status deployment coredns -n kube-system --timeout=60s"
  }
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
