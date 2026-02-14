terraform {
  source = "../../modules/registry-cache"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Preserve the image cache across destroy/apply cycles.
# To destroy explicitly: cd terraform/live/registry-cache && terragrunt destroy --non-interactive
exclude {
  if      = true
  actions = ["destroy"]
}

dependency "hcp_workspaces" {
  config_path  = "../hcp-workspaces"
  skip_outputs = true
}

# Serialize after transit-vault to avoid plugin cache race condition
# (both modules use kreuzwerker/docker provider)
dependency "transit_vault" {
  config_path  = "../transit-vault"
  skip_outputs = true
}
