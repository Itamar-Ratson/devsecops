terraform {
  source = "../../../modules/vault/transit"

  extra_arguments "secrets" {
    commands = get_terraform_commands_that_need_vars()

    optional_var_files = [
      "${get_repo_root()}/terraform/live/secrets.tfvars"
    ]
  }
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "hcp_workspaces" {
  config_path = "../../hcp-workspaces"
  mock_outputs = {
    workspace_ids = {}
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  vault_version = "1.21.2"
}
