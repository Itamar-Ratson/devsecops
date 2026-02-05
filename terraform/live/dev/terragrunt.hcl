# Root Terragrunt configuration for dev environment
# Configures HCP Terraform backend for all modules

locals {
  project_name = "devsecops"
  environment  = "dev"
}

# Configure HCP Terraform backend
# Sign up at: https://app.terraform.io/signup
# Configure: terraform login
remote_state {
  backend = "remote"

  config = {
    organization = "REPLACE_WITH_YOUR_ORG"

    workspaces {
      prefix = "${local.project_name}-${local.environment}-"
    }
  }
}

# Generate Terraform backend configuration
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<BACKEND
terraform {
  backend "remote" {}
}
BACKEND
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<PROVIDER
# Provider configurations are defined in individual modules
PROVIDER
}

# Common inputs for all Terragrunt units
inputs = {
  project_name = local.project_name
  environment  = local.environment
}
