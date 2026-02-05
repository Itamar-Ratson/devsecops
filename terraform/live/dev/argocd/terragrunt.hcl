# ArgoCD bootstrap module configuration
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/argocd-bootstrap"
}

dependency "cluster" {
  config_path = "../cluster"

  mock_outputs = {
    kubeconfig = "/tmp/mock-kubeconfig"
  }
}

inputs = {
  kubeconfig = dependency.cluster.outputs.kubeconfig

  # Secrets provided via secrets.tfvars
  git_repo_url           = ""
  argocd_ssh_private_key = ""
}
