feature "deploy_eks" {
  default = true
}

exclude {
  if      = !feature.deploy_eks.value
  actions = ["apply", "plan", "destroy"]
}

terraform {
  source = "../../../../modules/aws/eks/argocd-register"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "eks_cluster" {
  config_path = "../cluster"

  mock_outputs = {
    cluster_endpoint                   = "https://mock.eks.amazonaws.com"
    cluster_certificate_authority_data = "bW9jaw=="
    cluster_name                       = "devsecops-eks"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "eks_bootstrap" {
  config_path = "../bootstrap"

  mock_outputs = {
    argocd_manager_token = "mock-token"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "kind_cluster" {
  config_path = "../../../k8s/kind"

  mock_outputs = {
    endpoint               = "https://127.0.0.1:6443"
    cluster_ca_certificate = "mock-ca"
    client_certificate     = "mock-cert"
    client_key             = "mock-key"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# Ordering-only: ArgoCD must be deployed before we register clusters
dependencies {
  paths = ["./workspace", "../../../k8s/bootstrap/argocd"]
}

inputs = {
  # KinD cluster auth (where ArgoCD runs)
  kind_endpoint               = dependency.kind_cluster.outputs.endpoint
  kind_cluster_ca_certificate = dependency.kind_cluster.outputs.cluster_ca_certificate
  kind_client_certificate     = dependency.kind_cluster.outputs.client_certificate
  kind_client_key             = dependency.kind_cluster.outputs.client_key

  # EKS cluster details
  eks_cluster_endpoint = dependency.eks_cluster.outputs.cluster_endpoint
  eks_cluster_ca_data  = dependency.eks_cluster.outputs.cluster_certificate_authority_data
  eks_cluster_name     = dependency.eks_cluster.outputs.cluster_name
  argocd_manager_token = dependency.eks_bootstrap.outputs.argocd_manager_token

  git_repo_url = "https://github.com/Itamar-Ratson/devsecops.git"
}
