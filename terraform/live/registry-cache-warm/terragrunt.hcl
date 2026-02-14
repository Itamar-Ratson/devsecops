terraform {
  source = "../../modules/registry-cache-warm"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "hcp_workspaces" {
  config_path  = "../hcp-workspaces"
  skip_outputs = true
}

dependency "kind_cluster" {
  config_path = "../kind-cluster"
  mock_outputs = {
    cluster_name = "on-prem"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# Ordering only — ensures ArgoCD is deployed before warming the cache
dependency "argocd" {
  config_path  = "../argocd"
  skip_outputs = true
}

inputs = {
  cluster_name = dependency.kind_cluster.outputs.cluster_name
}
