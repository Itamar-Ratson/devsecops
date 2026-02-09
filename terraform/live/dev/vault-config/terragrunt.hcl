# Vault K8s auth config and secret seeding (post-cluster)
# Configures vault_kubernetes_auth_backend_config (needs cluster CA + endpoint)
# and seeds KV secrets + creates K8s secrets (vault-transit-token, argocd-oidc-secret)

terraform {
  source = "../../../modules/vault-config"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "vault" {
  config_path = "../vault"

  mock_outputs = {
    vault_address        = "http://192.168.100.2:8200"
    vault_token          = "root"
    kubernetes_auth_path = "kubernetes"
    kv_mount_path        = "secret"
  }
}

dependency "cluster" {
  config_path = "../cluster"

  mock_outputs = {
    kubeconfig       = "mock-kubeconfig"
    cluster_endpoint = "https://192.168.100.10:6443"
    cluster_ca_cert  = "mock-ca-cert"
  }
}

dependency "cluster_config" {
  config_path = "../cluster-config"

  mock_outputs = {
    token_reviewer_jwt = "mock-jwt"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

inputs = {
  # From vault module
  vault_address        = dependency.vault.outputs.vault_address
  vault_token          = dependency.vault.outputs.vault_token
  kubernetes_auth_path = dependency.vault.outputs.kubernetes_auth_path
  kv_mount_path        = dependency.vault.outputs.kv_mount_path

  # From cluster module
  kubeconfig       = dependency.cluster.outputs.kubeconfig
  cluster_endpoint = dependency.cluster.outputs.cluster_endpoint
  cluster_ca_cert  = dependency.cluster.outputs.cluster_ca_cert

  # From cluster-config module
  token_reviewer_jwt = dependency.cluster_config.outputs.token_reviewer_jwt

  # Secrets loaded from secrets.tfvars via root terragrunt.hcl:
  # - oidc_client_secrets
  # - keycloak_admin
  # - grafana_admin
  # - argocd_admin
  # - alertmanager_webhooks (optional)
}
