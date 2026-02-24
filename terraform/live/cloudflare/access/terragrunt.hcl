feature "destroy_cloud" {
  default = false
}

exclude {
  if      = !feature.destroy_cloud.value
  actions = ["destroy"]
}

terraform {
  source = "../../../modules/cloudflare/access"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  cloudflare_api_token   = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--name", "/devsecops/cloudflare-api-token", "--with-decryption", "--query", "Parameter.Value", "--output", "text")
  cloudflare_account_id  = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--name", "/devsecops/cloudflare-account-id", "--query", "Parameter.Value", "--output", "text")
  cloudflare_zone_id     = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--name", "/devsecops/cloudflare-zone-id", "--query", "Parameter.Value", "--output", "text")
  oidc_cloudflare_access = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--name", "/devsecops/oidc-cloudflare-access", "--with-decryption", "--query", "Parameter.Value", "--output", "text")
}

dependencies {
  paths = ["./workspace", "../tunnel"]
}

inputs = {
  cloudflare_api_token   = local.cloudflare_api_token
  cloudflare_account_id  = local.cloudflare_account_id
  cloudflare_zone_id     = local.cloudflare_zone_id
  keycloak_client_secret = local.oidc_cloudflare_access
}
