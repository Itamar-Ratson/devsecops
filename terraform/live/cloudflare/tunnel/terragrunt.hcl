feature "destroy_cloud" {
  default = false
}

exclude {
  if      = !feature.destroy_cloud.value
  actions = ["destroy"]
}

terraform {
  source = "../../../modules/cloudflare/tunnel"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  cloudflare_api_token  = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--name", "/devsecops/cloudflare-api-token", "--with-decryption", "--query", "Parameter.Value", "--output", "text")
  cloudflare_account_id = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--name", "/devsecops/cloudflare-account-id", "--query", "Parameter.Value", "--output", "text")
  cloudflare_zone_id    = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--name", "/devsecops/cloudflare-zone-id", "--query", "Parameter.Value", "--output", "text")
}

dependency "transit_vault" {
  config_path = "../../vault/transit"

  mock_outputs = {
    vault_token   = "mock-token"
    vault_address = "http://127.0.0.1:8200"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependencies {
  paths = ["./workspace"]
}

inputs = {
  cloudflare_api_token  = local.cloudflare_api_token
  cloudflare_account_id = local.cloudflare_account_id
  cloudflare_zone_id    = local.cloudflare_zone_id
  vault_address         = dependency.transit_vault.outputs.vault_address
  vault_token           = dependency.transit_vault.outputs.vault_token
}
