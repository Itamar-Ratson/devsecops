# Root Terragrunt configuration
# Configures HCP Terraform backend, secrets, and terrascan for all modules

locals {
  project_name = "devsecops"
  hcp_org_name = "itamar-ratson-hcp-org"
}

# HCP Terraform backend — one workspace per module
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      cloud {
        organization = "${local.hcp_org_name}"

        workspaces {
          name = "${local.project_name}-${path_relative_to_include()}"
        }
      }
    }
  EOF
}

# Minimal provider stub — actual providers defined in each module
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    # Provider configurations are defined in individual modules
  EOF
}

# Load secrets.tfvars for all terraform commands that accept variables
terraform {
  extra_arguments "secrets" {
    commands = get_terraform_commands_that_need_vars()

    optional_var_files = [
      "${get_terragrunt_dir()}/../secrets.tfvars"
    ]
  }

  # Terrascan security scan before every plan
  before_hook "terrascan" {
    commands = ["plan"]
    execute = [
      "terrascan", "scan",
      "--iac-type", "terraform",
      "--iac-dir", "${get_terragrunt_dir()}",
      "--non-recursive",
      "--policy-type", "k8s", "--policy-type", "docker",
      "--verbose"
    ]
  }
}

# Common inputs inherited by all modules
inputs = {
  project_name = local.project_name
}
