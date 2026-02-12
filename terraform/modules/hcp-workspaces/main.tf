terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.62"
    }
  }
}

provider "tfe" {}

# Create all project workspaces up front so they exist with correct settings
# before other modules run `terraform init` against the cloud backend.
resource "tfe_workspace" "this" {
  for_each = toset(var.workspace_names)

  name         = "${var.project_name}-${each.key}"
  organization = var.organization

  lifecycle {
    ignore_changes = [
      description,
      tag_names,
      vcs_repo,
    ]
  }
}

# Set execution mode via dedicated resource (non-deprecated).
# Local execution is required — all modules access local resources
# (Docker, KinD, kubectl) that HCP runners cannot reach.
resource "tfe_workspace_settings" "this" {
  for_each = tfe_workspace.this

  workspace_id   = each.value.id
  execution_mode = "local"
}
