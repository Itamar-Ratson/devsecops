# Cluster Config module configuration
# Installs Cilium, Gateway API CRDs, local-path-provisioner, cert-manager CA, Vault auth

terraform {
  source = "../../../modules/cluster-config"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "cluster" {
  config_path = "../cluster"

  mock_outputs = {
    kubeconfig         = "mock-kubeconfig"
    cluster_name       = "talos-dev"
    vm_controlplane_ip = "192.168.100.10"
  }

  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  kubeconfig         = dependency.cluster.outputs.kubeconfig
  cluster_name       = dependency.cluster.outputs.cluster_name
  vm_controlplane_ip = dependency.cluster.outputs.vm_controlplane_ip
  helm_values_dir    = "${get_repo_root()}/helm"
}
