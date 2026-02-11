terraform {
  source = "../../modules/kind-cluster"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "transit_vault" {
  config_path = "../transit-vault"

  mock_outputs = {
    container_name = "vault-transit"
    container_id   = "mock-container-id"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

locals {
  shared_values = yamldecode(file("${get_repo_root()}/helm/ports.yaml"))
}

inputs = {
  cluster_name         = local.shared_values.cluster.name
  vault_container_name = dependency.transit_vault.outputs.container_name
  vault_container_id   = dependency.transit_vault.outputs.container_id
}
