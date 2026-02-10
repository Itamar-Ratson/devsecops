provider "kubernetes" {
  host                   = var.endpoint
  cluster_ca_certificate = var.cluster_ca_certificate
  client_certificate     = var.client_certificate
  client_key             = var.client_key
}

provider "helm" {
  kubernetes {
    host                   = var.endpoint
    cluster_ca_certificate = var.cluster_ca_certificate
    client_certificate     = var.client_certificate
    client_key             = var.client_key
  }
}

resource "local_sensitive_file" "kubeconfig" {
  content  = var.kubeconfig
  filename = "${path.module}/.kubeconfig"
}

# ============================================================================
# Phase 1: Install ArgoCD with GitOps DISABLED
# (CRDs and VSO don't exist yet)
# ============================================================================
resource "helm_release" "argocd" {
  name      = "argocd"
  namespace = kubernetes_namespace.argocd.metadata[0].name
  chart     = "${var.helm_values_dir}/argocd"
  wait      = true
  timeout   = 300

  values = [
    file("${var.helm_values_dir}/ports.yaml"),
    file("${var.helm_values_dir}/argocd/values.yaml"),
    file("${var.helm_values_dir}/argocd/values-argocd.yaml"),
  ]

  set {
    name  = "gitops.repoURL"
    value = var.git_repo_url
  }

  set {
    name  = "gitops.enabled"
    value = "false"
  }

  set {
    name  = "vaultSecrets.enabled"
    value = "false"
  }

  depends_on = [
    null_resource.argocd_repo_creds,
    kubernetes_secret_v1.argocd_oidc,
    kubernetes_secret_v1.vault_transit_token,
    kubernetes_secret_v1.argocd_redis,
  ]
}

# Wait for ArgoCD server to be available
resource "null_resource" "wait_argocd" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig.filename
    }
    command = "kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=180s"
  }
}

# ============================================================================
# Phase 2: Enable GitOps — ArgoCD starts deploying all sync waves
# ============================================================================
resource "null_resource" "enable_gitops" {
  depends_on = [null_resource.wait_argocd]

  triggers = {
    repo_url = var.git_repo_url
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig.filename
    }
    command = <<-EOT
      helm upgrade argocd ${var.helm_values_dir}/argocd \
        -n argocd \
        -f ${var.helm_values_dir}/ports.yaml \
        -f ${var.helm_values_dir}/argocd/values.yaml \
        -f ${var.helm_values_dir}/argocd/values-argocd.yaml \
        --set gitops.enabled=true \
        --set gitops.repoURL=${var.git_repo_url} \
        --set vaultSecrets.enabled=false
    EOT
  }
}
