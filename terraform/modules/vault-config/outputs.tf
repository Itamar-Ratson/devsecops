output "kubernetes_auth_configured" {
  description = "Whether Kubernetes auth backend config has been applied"
  value       = true

  depends_on = [vault_kubernetes_auth_backend_config.main]
}
