output "token_reviewer_jwt" {
  description = "Service account JWT for Vault to validate K8s tokens via TokenReview API"
  value       = kubernetes_secret_v1.vault_auth_token.data["token"]
  sensitive   = true
}
