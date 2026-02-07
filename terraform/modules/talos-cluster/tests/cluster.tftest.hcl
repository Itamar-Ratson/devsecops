variables {
  network_id         = "test-network-id"
  network_name       = "test-network"
  vault_address      = "http://192.168.100.2:8200"
  helm_values_dir    = "${path.module}/../../../helm"
  vm_controlplane_ip = "192.168.100.10"
  vm_worker_ip       = "192.168.100.11"
}

run "validate_controlplane_vm" {
  command = plan

  assert {
    condition     = libvirt_domain.controlplane.name == "talos-dev-controlplane"
    error_message = "Control plane VM name should match cluster name"
  }

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

run "validate_worker_vm" {
  command = plan

  assert {
    condition     = libvirt_domain.worker.name == "talos-dev-worker"
    error_message = "Worker VM name should match cluster name"
  }

  assert {
    condition     = libvirt_domain.worker.memory == 4096
    error_message = "Worker should have 4GB RAM"
  }

  assert {
    condition     = libvirt_domain.worker.vcpu == 2
    error_message = "Worker should have 2 vCPUs"
  }

  assert {
    condition     = libvirt_domain.worker.autostart == true
    error_message = "Worker should autostart"
  }
}

run "validate_volumes" {
  command = plan

  assert {
    condition     = libvirt_volume.controlplane_disk.capacity == 21474836480
    error_message = "Control plane disk should be 20GB"
  }

  assert {
    condition     = libvirt_volume.worker_disk.capacity == 32212254720
    error_message = "Worker disk should be 30GB"
  }

  assert {
    condition     = can(regex("^https://github.com/siderolabs/talos", libvirt_volume.talos_iso.create.content.url))
    error_message = "Talos ISO should be downloaded from GitHub"
  }
}
