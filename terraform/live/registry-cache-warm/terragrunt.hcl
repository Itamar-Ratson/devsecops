terraform {
  source = "../../modules/registry-cache-warm"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "hcp_workspaces" {
  config_path = "../hcp-workspaces"
  mock_outputs = {
    workspace_ids = {}
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "kind_cluster" {
  config_path = "../kind-cluster"
  mock_outputs = {
    cluster_name = "on-prem"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "argocd" {
  config_path = "../argocd"
  mock_outputs = {
    argocd_namespace = "argocd"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  cluster_name = dependency.kind_cluster.outputs.cluster_name
}
