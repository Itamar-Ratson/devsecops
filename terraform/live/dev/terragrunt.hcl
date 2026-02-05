# Root Terragrunt configuration for dev environment
# Configures HCP Terraform backend for all modules

locals {
  project_name   = "devsecops"
  environment    = "dev"
  hcp_org_name   = "itamar-ratson-hcp-org"
}

# Configure HCP Terraform backend
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  cloud {
    organization = "${local.hcp_org_name}"

    workspaces {
      name = "${local.project_name}-${local.environment}-${path_relative_to_include()}"
    }
  }
}
EOF
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<PROVIDER
# Provider configurations are defined in individual modules
PROVIDER
}

# Load secrets from secrets.tfvars
terraform {
  extra_arguments "secrets" {
    commands = get_terraform_commands_that_need_vars()

    optional_var_files = [
      "${get_terragrunt_dir()}/../../secrets.tfvars"
    ]
  }
}

# Common inputs for all Terragrunt units
inputs = {
  project_name = local.project_name
  environment  = local.environment
}
