variables {
  network_id         = "test-network-id"
  vault_address      = "http://192.168.100.2:8200"
  vm_controlplane_ip = "192.168.100.10"
  vm_worker_ip       = "192.168.100.11"
}

run "validate_controlplane_resources" {
  command = plan

  assert {
    condition     = libvirt_domain.controlplane.memory == 2048
    error_message = "Control plane should have 2GB RAM"
  }

  assert {
    condition     = libvirt_domain.controlplane.vcpu == 2
    error_message = "Control plane should have 2 vCPUs"
  }

  assert {
    condition     = libvirt_domain.controlplane.autostart == true
    error_message = "Control plane should autostart"
  }
}

run "validate_worker_resources" {
  command = plan

  assert {
    condition     = libvirt_domain.worker.memory == 4096
    error_message = "Worker should have 4GB RAM"
  }

  assert {
    condition     = libvirt_domain.worker.vcpu == 2
    error_message = "Worker should have 2 vCPUs"
  }
}

run "validate_network_cidrs" {
  command = plan

  assert {
    condition     = contains(data.talos_machine_configuration.controlplane.config_patches, "10.10.0.0/16")
    error_message = "Pod CIDR should be 10.10.0.0/16"
  }

  assert {
    condition     = contains(data.talos_machine_configuration.controlplane.config_patches, "10.96.0.0/12")
    error_message = "Service CIDR should be 10.96.0.0/12"
  }
}
