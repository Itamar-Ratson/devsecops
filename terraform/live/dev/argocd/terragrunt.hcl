# ArgoCD Bootstrap module configuration
# Installs ArgoCD with GitOps configuration

terraform {
  source = "../../../modules/argocd-bootstrap"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "cluster" {
  config_path = "../cluster"

  mock_outputs = {
    kubeconfig       = "mock-kubeconfig"
    cluster_endpoint = "https://192.168.100.10:6443"
  }
}

dependency "vault_config" {
  config_path = "../vault-config"

  mock_outputs = {
    kubernetes_auth_configured = true
  }
}

inputs = {
  kubeconfig      = dependency.cluster.outputs.kubeconfig
  helm_values_dir = "${get_repo_root()}/helm"

  # Secrets loaded from secrets.tfvars via root terragrunt.hcl:
  # - git_repo_url
  # - argocd_ssh_private_key
}
