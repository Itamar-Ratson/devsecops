# Talos cluster module configuration
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/talos-cluster"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    network_id = "mock-network-id"
  }
}

dependency "vault" {
  config_path = "../vault"

  mock_outputs = {
    vault_address = "http://192.168.100.2:8200"
  }
}

inputs = {
  network_id = dependency.network.outputs.network_id

  cluster_name = "talos-dev"
  talos_version = "v1.8"

  vm_controlplane_ip = "192.168.100.10"
  vm_worker_ip       = "192.168.100.11"

  controlplane_memory = 2048
  controlplane_vcpu   = 2

  worker_memory = 4096
  worker_vcpu   = 2

  pod_cidr     = "10.10.0.0/16"
  service_cidr = "10.96.0.0/12"

  vault_address = dependency.vault.outputs.vault_address
}
