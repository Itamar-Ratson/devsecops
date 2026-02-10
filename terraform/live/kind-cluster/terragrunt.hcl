terraform {
  source = "../../modules/kind-cluster"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "transit_vault" {
  config_path = "../transit-vault"

  mock_outputs = {
    container_name = "vault-transit"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  cluster_name         = "k8s-dev"
  vault_container_name = dependency.transit_vault.outputs.container_name
}
