terraform {
  source = "../../modules/cluster-bootstrap"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "kind_cluster" {
  config_path = "../kind-cluster"

  mock_outputs = {
    kubeconfig             = "mock"
    endpoint               = "https://127.0.0.1:6443"
    cluster_ca_certificate = "mock-ca"
    client_certificate     = "mock-cert"
    client_key             = "mock-key"
    cache_cluster_ip       = "172.18.0.101"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  kubeconfig             = dependency.kind_cluster.outputs.kubeconfig
  endpoint               = dependency.kind_cluster.outputs.endpoint
  cluster_ca_certificate = dependency.kind_cluster.outputs.cluster_ca_certificate
  client_certificate     = dependency.kind_cluster.outputs.client_certificate
  client_key             = dependency.kind_cluster.outputs.client_key
  cache_cluster_ip       = dependency.kind_cluster.outputs.cache_cluster_ip
  helm_values_dir        = "${get_repo_root()}/helm"
}
