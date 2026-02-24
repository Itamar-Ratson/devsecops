# terraform/live/vault/transit/workspace/terragrunt.hcl

feature "destroy_onprem" {
  default = false
}

exclude {
  if      = !feature.destroy_onprem.value
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
  workspace_name = "devsecops-vault-transit"
  organization   = "itamar-ratson-hcp-org"
  execution_mode = "local"
}
