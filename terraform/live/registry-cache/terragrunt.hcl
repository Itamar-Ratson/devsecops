terraform {
  source = "../../modules/registry-cache"
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

# Serialize after transit-vault to avoid plugin cache race condition
# (both modules use kreuzwerker/docker provider)
dependency "transit_vault" {
  config_path = "../transit-vault"
  mock_outputs = {
    container_name = "vault-transit"
    container_id   = "mock-id"
    vault_token    = "mock-token"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}
