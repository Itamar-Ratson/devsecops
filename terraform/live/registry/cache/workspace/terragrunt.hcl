# terraform/live/registry/cache/workspace/terragrunt.hcl
terraform {
  source = "../../../../modules/hcp-workspace"

  # Local backend requires explicit -auto-approve for --non-interactive runs
  extra_arguments "auto_approve" {
    commands  = ["apply", "destroy"]
    arguments = ["-auto-approve"]
  }
}

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
  workspace_name = "devsecops-registry-cache"
  organization   = "itamar-ratson-hcp-org"
  execution_mode = "local"
}
