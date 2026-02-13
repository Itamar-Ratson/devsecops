terraform {
  source = "../../modules/hcp-workspaces"

  # Local backend doesn't auto-approve with --non-interactive,
  # so pass -auto-approve explicitly for apply/destroy.
  extra_arguments "auto_approve" {
    commands  = ["apply", "destroy"]
    arguments = ["-auto-approve"]
  }
}

# Local backend — this module bootstraps HCP workspaces, cannot depend on them
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      backend "local" {}
    }
  EOF
}

inputs = {
  organization = "itamar-ratson-hcp-org"
  project_name = "devsecops"

  workspace_names = [
    "registry-cache",
    "transit-vault",
    "kind-cluster",
    "cluster-bootstrap",
    "vault-config",
    "argocd",
  ]
}
