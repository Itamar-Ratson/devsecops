# terraform/live/aws/ssm/terragrunt.hcl
#
# Admin-only: seeds all SSM SecureString parameters from secrets.tfvars.
# Apply manually before running the full stack:
#   1. Ensure terraform/live/secrets.tfvars is fully populated
#   2. cd terraform/live/aws/ssm && terragrunt apply --non-interactive

feature "destroy_cloud" {
  default = false
}

exclude {
  if      = !feature.destroy_cloud.value
  actions = ["destroy"]
}

terraform {
  source = "../../../modules/aws/ssm"

  # Admin-only module, always run individually (not via run --all).
  extra_arguments "auto_approve" {
    commands  = ["apply", "destroy"]
    arguments = ["-auto-approve"]
  }

  # Fail loudly if secrets.tfvars is missing — this is admin-only and
  # must be present to seed SSM.
  extra_arguments "secrets" {
    commands = get_terraform_commands_that_need_vars()

    required_var_files = [
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
