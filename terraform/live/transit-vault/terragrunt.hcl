terraform {
  source = "../../modules/transit-vault"
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

inputs = {
  vault_version = "1.21.2"
}
