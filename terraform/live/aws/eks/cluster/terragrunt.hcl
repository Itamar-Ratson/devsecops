feature "deploy_eks" {
  default = true
}

exclude {
  if      = !feature.deploy_eks.value
  actions = ["apply", "plan", "destroy"]
}

terraform {
  source = "../../../../modules/aws/eks/cluster"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-mock"]
    vpc_cidr_block     = "10.50.0.0/16"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependencies {
  paths = ["./workspace"]
}

inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  helm_values_dir    = "${get_repo_root()}/helm"
}
