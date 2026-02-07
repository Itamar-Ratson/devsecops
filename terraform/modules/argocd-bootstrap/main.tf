provider "kubernetes" {
  config_path = var.kubeconfig
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig
  }
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_secret_v1" "argocd_repo_creds" {
  depends_on = [kubernetes_namespace_v1.argocd]

  metadata {
    name      = "argocd-repo-creds"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
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

resource "helm_release" "argocd" {
  depends_on = [kubernetes_secret_v1.argocd_repo_creds]

  name       = "argocd"
  repository = "file://${var.helm_values_dir}/argocd"
  chart      = "argocd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  values = [
    file("${var.helm_values_dir}/ports.yaml"),
    file("${var.helm_values_dir}/argocd/values.yaml"),
    file("${var.helm_values_dir}/argocd/values-argocd.yaml")
  ]

  set = [
    {
      name  = "gitops.enabled"
      value = "true"
    },
    {
      name  = "gitops.repoURL"
      value = var.git_repo_url
    }
  ]
}

resource "null_resource" "wait_argocd" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${var.kubeconfig} wait --for=condition=Available deployment/argocd-server -n argocd --timeout=180s"
  }
}
