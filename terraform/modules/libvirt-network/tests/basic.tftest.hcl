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
    condition     = libvirt_network.main.forward.mode == "nat"
    error_message = "Network forward mode should be NAT"
  }

  assert {
    condition     = libvirt_network.main.domain.name == "k8s.local"
    error_message = "Domain name should be k8s.local"
  }

  assert {
    condition     = libvirt_network.main.bridge.name == "virbr-k8s"
    error_message = "Bridge name should be virbr-k8s"
  }

  assert {
    condition     = libvirt_network.main.autostart == true
    error_message = "Network should be set to autostart"
  }
}
