variables {
  network_name = "k8s-test"
  network_cidr = "192.168.100.0/24"
}

run "validate_network_configuration" {
  command = plan

  assert {
    condition     = libvirt_network.main.name == "k8s-test"
    error_message = "Network name should be k8s-test"
  }

  assert {
    condition     = libvirt_network.main.mode == "nat"
    error_message = "Network mode should be NAT"
  }

  assert {
    condition     = contains(libvirt_network.main.addresses, "192.168.100.0/24")
    error_message = "Network CIDR should be 192.168.100.0/24"
  }

  assert {
    condition     = libvirt_network.main.dhcp[0].enabled == false
    error_message = "DHCP should be disabled"
  }

  assert {
    condition     = libvirt_network.main.autostart == true
    error_message = "Network should be set to autostart"
  }
}
