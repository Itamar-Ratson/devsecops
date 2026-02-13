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
