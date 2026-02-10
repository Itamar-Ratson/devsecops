terraform {
  source = "../../modules/vault-config"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "transit_vault" {
  config_path = "../transit-vault"

  mock_outputs = {
    vault_address = "http://127.0.0.1:8100"
    vault_token   = "mock-token"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "kind_cluster" {
  config_path = "../kind-cluster"

  mock_outputs = {
    control_plane_ip       = "172.18.0.2"
    cluster_ca_certificate = "mock-ca"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "cluster_bootstrap" {
  config_path = "../cluster-bootstrap"

  mock_outputs = {
    token_reviewer_jwt = "mock-jwt"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  vault_address          = dependency.transit_vault.outputs.vault_address
  vault_token            = dependency.transit_vault.outputs.vault_token
  control_plane_ip       = dependency.kind_cluster.outputs.control_plane_ip
  cluster_ca_certificate = dependency.kind_cluster.outputs.cluster_ca_certificate
  token_reviewer_jwt     = dependency.cluster_bootstrap.outputs.token_reviewer_jwt
  # oidc_client_secrets, keycloak_admin, grafana_admin, argocd_admin,
  # alertmanager_webhooks — loaded from secrets.tfvars via root extra_arguments
}
