output "vault_address" {
  description = "Vault address accessible from the host"
  value       = "http://127.0.0.1:${var.host_port}"
}

output "vault_token" {
  description = "Vault root token"
  value       = var.vault_root_token
  sensitive   = true
}

output "container_name" {
  description = "Name of the Vault Docker container"
  value       = docker_container.vault.name
}

output "transit_mount_path" {
  description = "Mount path for transit engine"
  value       = "transit"
}

output "kv_mount_path" {
  description = "Mount path for KV v2 engine"
  value       = "secret"
}
