output "autounseal_key_name" {
  description = "Name of the autounseal key in transit engine"
  value       = vault_transit_secret_backend_key.autounseal.name
}

output "kubernetes_auth_path" {
  description = "Path to the Kubernetes auth backend"
  value       = vault_auth_backend.kubernetes.path
}

output "kv_mount_path" {
  description = "Path to the KV v2 secret engine"
  value       = vault_mount.kv.path
}

output "transit_mount_path" {
  description = "Path to the transit engine"
  value       = vault_mount.transit.path
}

output "vault_address" {
  description = "Address of the Vault server"
  value       = "http://${var.vm_ip}:8200"
}

output "vault_token" {
  description = "Root token for Vault dev mode"
  value       = "root"
  sensitive   = true
}

output "vm_ip" {
  description = "IP address of the Vault VM"
  value       = var.vm_ip
}
