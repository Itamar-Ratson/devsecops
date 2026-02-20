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

dependencies {
  paths = ["./workspace"]
}

inputs = {
  vault_version = "1.21.2"
}
