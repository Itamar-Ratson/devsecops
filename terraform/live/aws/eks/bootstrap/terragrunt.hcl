feature "deploy_eks" {
  default = true
}

exclude {
  if      = !feature.deploy_eks.value
  actions = ["apply", "plan", "destroy"]
}

terraform {
  source = "../../../../modules/aws/eks/bootstrap"
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
    cluster_oidc_provider_arn          = "arn:aws:iam::123456789012:oidc-provider/mock"
    cluster_oidc_issuer_url            = "https://oidc.eks.eu-north-1.amazonaws.com/id/MOCK"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependencies {
  paths = ["./workspace"]
}

inputs = {
  cluster_endpoint         = dependency.eks_cluster.outputs.cluster_endpoint
  cluster_ca_data          = dependency.eks_cluster.outputs.cluster_certificate_authority_data
  cluster_name             = dependency.eks_cluster.outputs.cluster_name
  cluster_oidc_provider_arn = dependency.eks_cluster.outputs.cluster_oidc_provider_arn
  cluster_oidc_issuer_url  = dependency.eks_cluster.outputs.cluster_oidc_issuer_url
  helm_values_dir          = "${get_repo_root()}/helm"
}
