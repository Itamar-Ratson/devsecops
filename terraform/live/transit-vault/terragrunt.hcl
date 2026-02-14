terraform {
  source = "../../modules/transit-vault"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "hcp_workspaces" {
  config_path  = "../hcp-workspaces"
  skip_outputs = true
}

inputs = {
  vault_version = "1.21.2"
}
