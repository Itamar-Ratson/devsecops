# terraform/live/k8s/bootstrap/argocd/workspace/terragrunt.hcl
terraform {
  source = "../../../../../modules/hcp-workspace"

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
  workspace_name = "devsecops-k8s-bootstrap-argocd"
  organization   = "itamar-ratson-hcp-org"
  execution_mode = "local"
}
