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
  force_delete = true

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

# Seed empty state into new workspaces so `terraform output -json` succeeds.
# Without this, terragrunt can't resolve dependency outputs during destroy.
resource "terraform_data" "seed_empty_state" {
  for_each = tfe_workspace.this

  triggers_replace = each.value.id

  provisioner "local-exec" {
    command = <<-EOT
      TOKEN="$TFE_TOKEN"
      [ -z "$TOKEN" ] && TOKEN=$(jq -r '.credentials["app.terraform.io"].token' "$HOME/.terraform.d/credentials.tfrc.json")
      WS="${each.value.id}"
      API="https://app.terraform.io/api/v2"
      AUTH="Authorization: Bearer $TOKEN"

      # Skip if workspace already has state
      curl -sf -H "$AUTH" "$API/workspaces/$WS" \
        | jq -e '.data.relationships["current-state-version"].data' >/dev/null 2>&1 \
        && exit 0

      # Seed empty state: lock, push, unlock
      STATE='{"version":4,"terraform_version":"1.12.0","serial":0,"lineage":"00000000-0000-0000-0000-000000000000","outputs":{},"resources":[]}'
      B64=$(echo -n "$STATE" | base64 -w0)
      MD5=$(echo -n "$STATE" | md5sum | cut -d' ' -f1)
      BODY="{\"data\":{\"type\":\"state-versions\",\"attributes\":{\"serial\":0,\"md5\":\"$MD5\",\"state\":\"$B64\"}}}"

      curl -sf -X POST -H "$AUTH" -H "Content-Type: application/vnd.api+json" -d '{"reason":"seed"}' "$API/workspaces/$WS/actions/lock" >/dev/null
      curl -sf -X POST -H "$AUTH" -H "Content-Type: application/vnd.api+json" -d "$BODY" "$API/workspaces/$WS/state-versions" >/dev/null
      curl -sf -X POST -H "$AUTH" -H "Content-Type: application/vnd.api+json" "$API/workspaces/$WS/actions/unlock" >/dev/null
    EOT
  }

  depends_on = [tfe_workspace_settings.this]
}
