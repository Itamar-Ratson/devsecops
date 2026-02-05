# Vault VM module configuration
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/vault-vm"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    network_id   = "mock-network-id"
    network_name = "mock-network"
  }
}

inputs = {
  network_id   = dependency.network.outputs.network_id
  network_name = dependency.network.outputs.network_name

  vm_name    = "transit-vault"
  vm_ip      = "192.168.100.2"
  vm_memory  = 512
  vm_vcpu    = 1

  vault_version = "1.15.0"

  # Secrets provided via secrets.tfvars
  oidc_client_secrets = {
    argocd   = ""
    grafana  = ""
    vault    = ""
    headlamp = ""
  }

  keycloak_admin = {
    user     = ""
    password = ""
  }

  grafana_admin = {
    user     = ""
    password = ""
  }

  argocd_admin = {
    password_hash     = ""
    server_secret_key = ""
  }

  alertmanager_webhooks = {}
}
