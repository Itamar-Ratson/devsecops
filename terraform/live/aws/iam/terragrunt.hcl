# terraform/live/aws/iam/terragrunt.hcl
#
# Admin-only: provisions OIDC provider, GitHub Actions role, and per-member IAM users.
# Apply manually before running the full stack:
#   cd terraform/live/aws/iam && terragrunt apply --non-interactive
#
# Pre-requisite: copy team-members.csv.example to team-members.csv and add usernames.

feature "destroy_cloud" {
  default = false
}

exclude {
  if      = !feature.destroy_cloud.value
  actions = ["destroy"]
}

terraform {
  source = "../../../modules/aws/iam"

  # Admin-only module, always run individually (not via run --all).
  extra_arguments "auto_approve" {
    commands  = ["apply", "destroy"]
    arguments = ["-auto-approve"]
  }
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependencies {
  paths = ["./workspace"]
}

locals {
  team_members = {
    for row in csvdecode(file("${get_terragrunt_dir()}/team-members.csv")) :
    row.username => {}
  }
}

inputs = {
  aws_region   = "eu-north-1"
  github_org   = "itamar-ratson"
  github_repo  = "devsecops"
  project_name = "devsecops"
  team_members = local.team_members
}
