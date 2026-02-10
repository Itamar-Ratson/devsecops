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
    kubeconfig             = "mock"
    endpoint               = "https://127.0.0.1:6443"
    cluster_ca_certificate = "mock-ca"
    client_certificate     = "mock-cert"
    client_key             = "mock-key"
    vault_cluster_ip       = "172.18.0.100"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "vault_config" {
  config_path = "../vault-config"

  mock_outputs = {
    kubernetes_auth_configured = true
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  endpoint               = dependency.kind_cluster.outputs.endpoint
  cluster_ca_certificate = dependency.kind_cluster.outputs.cluster_ca_certificate
  client_certificate     = dependency.kind_cluster.outputs.client_certificate
  client_key             = dependency.kind_cluster.outputs.client_key
  kubeconfig             = dependency.kind_cluster.outputs.kubeconfig
  vault_root_token       = dependency.transit_vault.outputs.vault_token
  vault_cluster_ip       = dependency.kind_cluster.outputs.vault_cluster_ip
  helm_values_dir        = "${get_repo_root()}/helm"
  # git_repo_url, argocd_ssh_private_key, argocd_oidc_client_secret
  # — loaded from secrets.tfvars via root extra_arguments
}
