# Transit Vault VM module configuration (pre-cluster)
# Creates Vault VM and configures engines, transit key, policy, auth backend + role
# K8s auth config and secret seeding happen in vault-config (post-cluster)

terraform {
  source = "../../../modules/vault-vm"
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

inputs = {
  vm_name   = "vault-dev"
  vm_memory = 512
  vm_vcpu   = 1

  network_name = dependency.network.outputs.network_name
  network_id   = dependency.network.outputs.network_id
  vm_ip        = "192.168.100.2"

  # Note: Secret seeding happens in the vault-config module (post-cluster)
}
