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

inputs = {
  kubeconfig = dependency.cluster.outputs.kubeconfig
}
