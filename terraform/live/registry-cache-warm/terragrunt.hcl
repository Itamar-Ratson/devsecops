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
}

dependency "kind_cluster" {
  config_path = "../kind-cluster"
  mock_outputs = {
    cluster_name     = "on-prem"
    cache_cluster_ip = "172.18.0.101"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  cluster_name     = dependency.kind_cluster.outputs.cluster_name
  cache_cluster_ip = dependency.kind_cluster.outputs.cache_cluster_ip
}
