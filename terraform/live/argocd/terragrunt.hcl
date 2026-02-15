terraform {
  source = "../../modules/argocd-bootstrap"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "transit_vault" {
  config_path = "../transit-vault"

  mock_outputs = {
    vault_token = "mock-token"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "kind_cluster" {
  config_path = "../kind-cluster"

  mock_outputs = {
    endpoint               = "https://127.0.0.1:6443"
    cluster_ca_certificate = "mock-ca"
    client_certificate     = "mock-cert"
    client_key             = "mock-key"
    vault_cluster_ip       = "172.18.0.100"
    cache_cluster_ip       = "172.18.0.101"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# Ordering-only deps whose outputs argocd doesn't reference.
# Uses dependencies (not dependency) to avoid evaluation failures
# when vault-config is filtered in CI.
# - cluster-bootstrap: CRDs (ArgoCD Application, CiliumNetworkPolicy, etc.)
# - vault-config: Vault auth backend setup
dependencies {
  paths = ["../cluster-bootstrap", "../vault-config"]
}

inputs = {
  endpoint               = dependency.kind_cluster.outputs.endpoint
  cluster_ca_certificate = dependency.kind_cluster.outputs.cluster_ca_certificate
  client_certificate     = dependency.kind_cluster.outputs.client_certificate
  client_key             = dependency.kind_cluster.outputs.client_key
  vault_root_token       = dependency.transit_vault.outputs.vault_token
  vault_cluster_ip       = dependency.kind_cluster.outputs.vault_cluster_ip
  cache_cluster_ip       = dependency.kind_cluster.outputs.cache_cluster_ip
  helm_values_dir        = "${get_repo_root()}/helm"
  # git_repo_url, github_token, argocd_oidc_client_secret
  # — loaded from secrets.tfvars via root extra_arguments
}
