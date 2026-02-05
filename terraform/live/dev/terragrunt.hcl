# Root Terragrunt configuration for dev environment

locals {
  environment = "dev"
  project     = "devsecops"
}

# Generate backend configuration for HCP Terraform
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "remote" {
    organization = "itamar-ratson-hcp-org"

    workspaces {
      name = "${local.project}-${local.environment}-${path_relative_to_include()}"
    }
  }
}
EOF
}

# Common terraform configuration
terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()

    optional_var_files = [
      "${get_repo_root()}/terraform/secrets.tfvars"
    ]
  }

  extra_arguments "retry_lock" {
    commands = get_terraform_commands_that_need_locking()

    arguments = [
      "-lock-timeout=5m"
    ]
  }
}
