terraform {
  source = "../../../../modules/k8s/bootstrap/argocd"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Fetch secrets from SSM at plan/apply time.
# CI also has AWS credentials (via GitHub OIDC AssumeRole), so these succeed in CI too.
# Non-sensitive CI overrides (create_deploy_key, juice_shop_enabled, git_repo_url for HTTPS)
# are written to ci.auto.tfvars by the workflow; auto.tfvars override these locals.
locals {
  github_token              = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--name", "/devsecops/github-token", "--with-decryption", "--query", "Parameter.Value", "--output", "text")
  argocd_oidc_client_secret = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--name", "/devsecops/oidc-argocd", "--with-decryption", "--query", "Parameter.Value", "--output", "text")
}

dependency "transit_vault" {
  config_path = "../../../vault/transit"

  mock_outputs = {
    vault_token = "mock-token"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "kind_cluster" {
  config_path = "../../kind"

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
# - k8s/bootstrap/cluster: CRDs (ArgoCD Application, CiliumNetworkPolicy, etc.)
# - vault-config: Vault auth backend setup
dependencies {
  paths = ["./workspace", "../cluster", "../../../vault/config"]
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

  # SSH URL for local deploy key setup.
  # In CI: ci.auto.tfvars overrides with HTTPS URL (public repo, no deploy key).
  git_repo_url = "git@github.com:itamar-ratson/devsecops.git"

  github_token              = local.github_token
  argocd_oidc_client_secret = local.argocd_oidc_client_secret
}
