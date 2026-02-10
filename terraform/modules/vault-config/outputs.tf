output "kubernetes_auth_configured" {
  description = "Whether K8s auth backend is configured"
  value       = true

  depends_on = [
    vault_kubernetes_auth_backend_config.this,
    vault_kubernetes_auth_backend_role.vso,
  ]
}
