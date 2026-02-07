variables {
  kubeconfig             = "/tmp/test-kubeconfig"
  git_repo_url           = "git@github.com:test/repo.git"
  argocd_ssh_private_key = "test-private-key"
}

run "validate_namespace" {
  command = plan

  assert {
    condition     = kubernetes_namespace_v1.argocd.metadata[0].name == "argocd"
    error_message = "ArgoCD namespace should be 'argocd'"
  }
}

run "validate_repo_secret" {
  command = plan

  assert {
    condition     = kubernetes_secret_v1.argocd_repo_creds.metadata[0].name == "argocd-repo-creds"
    error_message = "Repository secret should be named 'argocd-repo-creds'"
  }

  assert {
    condition     = kubernetes_secret_v1.argocd_repo_creds.metadata[0].labels["argocd.argoproj.io/secret-type"] == "repo-creds"
    error_message = "Secret should have ArgoCD repo-creds label"
  }
}

run "validate_helm_release" {
  command = plan

  assert {
    condition     = helm_release.argocd.name == "argocd"
    error_message = "Helm release should be named 'argocd'"
  }

  assert {
    condition     = helm_release.argocd.chart == "argocd"
    error_message = "Helm chart should be 'argocd'"
  }
}
