terraform {
  source = "../../modules/registry-cache"

  # Cloud backend doesn't auto-approve with --non-interactive,
  # so pass -auto-approve explicitly for apply/destroy.
  extra_arguments "auto_approve" {
    commands  = ["apply", "destroy"]
    arguments = ["-auto-approve"]
  }
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Preserve the image cache across destroy/apply cycles.
# To destroy explicitly: cd terraform/live/registry-cache && terragrunt destroy --non-interactive
exclude {
  if      = get_terragrunt_dir() != get_original_terragrunt_dir()
  actions = ["destroy"]
}

dependency "hcp_workspaces" {
  config_path = "../hcp-workspaces"
  mock_outputs = {
    workspace_ids = {}
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
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
  mock_outputs_merge_strategy_with_state  = "shallow"
}
