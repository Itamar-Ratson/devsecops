provider "kubernetes" {
  config_path = var.kubeconfig
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_secret" "argocd_repo_creds" {
  depends_on = [kubernetes_namespace.argocd]

  metadata {
    name      = "argocd-repo-creds"
    namespace = kubernetes_namespace.argocd.metadata[0].name
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
  depends_on = [kubernetes_secret.argocd_repo_creds]

  name       = "argocd"
  repository = "file://../../../helm/argocd"
  chart      = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    file("${path.root}/../../../helm/ports.yaml"),
    file("${path.root}/../../../helm/argocd/values.yaml"),
    file("${path.root}/../../../helm/argocd/values-argocd.yaml")
  ]

  set {
    name  = "gitops.enabled"
    value = "true"
  }

  set {
    name  = "gitops.repoURL"
    value = var.git_repo_url
  }
}

resource "null_resource" "wait_argocd" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${var.kubeconfig} wait --for=condition=Available deployment/argocd-server -n argocd --timeout=180s"
  }
}
