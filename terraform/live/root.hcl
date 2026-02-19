# Root Terragrunt configuration
# Configures backend, CI auto-approve, and Trivy IaC scan for all modules

locals {
  project_name   = "devsecops"
  hcp_org_name   = "itamar-ratson-hcp-org"
  is_ci          = get_env("CI", "") != ""
  workspace_name = replace(path_relative_to_include(), "/", "-")

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
          name = "${local.project_name}-${local.workspace_name}"
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

terraform {
  # Auto-approve in CI (local backend requires explicit -auto-approve)
  extra_arguments "ci_auto_approve" {
    commands  = ["apply", "destroy"]
    arguments = local.is_ci ? ["-auto-approve"] : []
  }

  # Trivy IaC scan before every plan (skip in CI — handled by Trivy in the security workflow)
  before_hook "trivy" {
    commands = ["plan"]
    execute = local.is_ci ? ["echo", "Skipping trivy in CI"] : [
      "trivy", "config", ".",
      "--severity", "HIGH,CRITICAL",
      "--exit-code", "1",
    ]
  }
}

