# terraform/live/cloudflare/tunnel/workspace/terragrunt.hcl

feature "destroy_cloud" {
  default = false
}

exclude {
  if      = !feature.destroy_cloud.value
  actions = ["destroy"]
}

terraform {
  source = "../../../../modules/hcp-workspace"

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
  workspace_name = "devsecops-cloudflare-tunnel"
  organization   = "itamar-ratson-hcp-org"
  execution_mode = "local"
}
