output "token_reviewer_jwt" {
  description = "JWT token for Vault to validate K8s service account tokens"
  value       = kubernetes_secret_v1.vault_auth_token.data["token"]
  sensitive   = true
}
