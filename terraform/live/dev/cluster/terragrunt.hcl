# Talos Cluster module configuration
# Creates Talos VMs, bootstraps cluster, generates kubeconfig

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

inputs = {
  cluster_name = "talos-dev"

  network_name = dependency.network.outputs.network_name
  network_id   = dependency.network.outputs.network_id

  vm_controlplane_ip = "192.168.100.10"
  vm_worker_ip       = "192.168.100.11"

  controlplane_memory = 4096
  controlplane_vcpu   = 3
  worker_memory       = 8192
  worker_vcpu         = 4

  pod_cidr     = "10.10.0.0/16"
  service_cidr = "10.96.0.0/12"
}
