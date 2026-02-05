resource "libvirt_network" "main" {
  name      = var.network_name
  autostart = true

  forward = {
    mode = "nat"
  }

  domain = {
    name = "k8s.local"
  }

  bridge = {
    name = var.network_bridge
  }

  ips = [{
    address = cidrhost(var.network_cidr, 1)
    netmask = cidrnetmask(var.network_cidr)
  }]
}
