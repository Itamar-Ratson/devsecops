output "network_bridge" {
  description = "Bridge name of the created network"
  value       = libvirt_network.main.bridge
}

output "network_cidr" {
  description = "CIDR block of the network"
  value       = var.network_cidr
}

output "network_id" {
  description = "ID of the created libvirt network"
  value       = libvirt_network.main.id
}

output "network_name" {
  description = "Name of the created libvirt network"
  value       = libvirt_network.main.name
}
