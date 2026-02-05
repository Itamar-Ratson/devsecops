# Network module configuration
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/libvirt-network"
}

inputs = {
  network_name   = "k8s-dev"
  network_cidr   = "192.168.100.0/24"
  network_bridge = "virbr-k8s"
}
