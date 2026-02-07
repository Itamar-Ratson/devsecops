variables {
  network_id   = "test-network-id"
  network_name = "k8s-test"
  vm_ip        = "192.168.100.2"
}

run "validate_vm_configuration" {
  command = plan

  assert {
    condition     = libvirt_domain.vault.memory == 512
    error_message = "Vault VM should have 512MB RAM"
  }

  assert {
    condition     = libvirt_domain.vault.vcpu == 1
    error_message = "Vault VM should have 1 vCPU"
  }

  assert {
    condition     = libvirt_domain.vault.autostart == true
    error_message = "Vault VM should be set to autostart"
  }
}

run "validate_vault_engines" {
  command = plan

  assert {
    condition     = vault_mount.transit.path == "transit"
    error_message = "Transit engine should be mounted at 'transit'"
  }

  assert {
    condition     = vault_mount.kv.path == "secret"
    error_message = "KV engine should be mounted at 'secret'"
  }

  assert {
    condition     = vault_mount.kv.type == "kv-v2"
    error_message = "KV engine should be version 2"
  }
}

run "validate_vault_auth" {
  command = plan

  assert {
    condition     = vault_auth_backend.kubernetes.type == "kubernetes"
    error_message = "Kubernetes auth backend should be enabled"
  }

  assert {
    condition     = vault_kubernetes_auth_backend_role.vso.role_name == "vso"
    error_message = "VSO role should be named 'vso'"
  }
}
