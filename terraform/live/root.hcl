# Root Terragrunt configuration
# Configures backend, secrets, and terrascan for all modules

locals {
  project_name = "devsecops"
  hcp_org_name = "itamar-ratson-hcp-org"
  is_ci        = get_env("CI", "") != ""

  ci_backend = <<-EOF
    terraform {
      backend "local" {}
    }
  EOF

  hcp_backend = <<-EOF
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

# HCP Terraform backend (production) or local backend (CI)
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.is_ci ? local.ci_backend : local.hcp_backend
}

# Load secrets.tfvars for all terraform commands that accept variables
terraform {
  extra_arguments "secrets" {
    commands = get_terraform_commands_that_need_vars()

    optional_var_files = [
      "${get_terragrunt_dir()}/../secrets.tfvars"
    ]
  }

  # Auto-approve in CI (local backend requires explicit -auto-approve)
  extra_arguments "ci_auto_approve" {
    commands  = ["apply", "destroy"]
    arguments = local.is_ci ? ["-auto-approve"] : []
  }

  # Terrascan security scan before every plan (skip in CI — Trivy handles IaC scanning)
  before_hook "terrascan" {
    commands = ["plan"]
    execute = local.is_ci ? ["echo", "Skipping terrascan in CI"] : [
      "terrascan", "scan",
      "--iac-type", "terraform",
      "--iac-dir", "${get_terragrunt_dir()}",
      "--non-recursive",
      "--policy-type", "k8s", "--policy-type", "docker",
      "--verbose"
    ]
  }
}

