# Talos Cluster module configuration
# Creates Talos VMs, bootstraps cluster, installs Cilium, configures mkcert CA

terraform {
  source = "../../../modules/talos-cluster"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    network_name = "k8s-dev"
    network_id   = "mock-network-id"
  }
}

dependency "vault" {
  config_path = "../vault"

  mock_outputs = {
    vault_address = "http://192.168.100.2:8200"
  }
}

inputs = {
  cluster_name    = "talos-dev"
  helm_values_dir = "${get_repo_root()}/helm"

  network_name = dependency.network.outputs.network_name
  network_id   = dependency.network.outputs.network_id

  vm_controlplane_ip = "192.168.100.10"
  vm_worker_ip       = "192.168.100.11"

  controlplane_memory = 2048
  controlplane_vcpu   = 2
  worker_memory       = 4096
  worker_vcpu         = 2

  pod_cidr     = "10.10.0.0/16"
  service_cidr = "10.96.0.0/12"

  vault_address = dependency.vault.outputs.vault_address
}
