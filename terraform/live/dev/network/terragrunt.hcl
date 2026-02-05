# Network module configuration
# Creates libvirt network with NAT for internet access

terraform {
  source = "../../../modules/libvirt-network"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  network_name = "k8s-dev"
  network_cidr = "192.168.100.0/24"
  dhcp_enabled = false
}
