output "identity_provider_id" {
  description = "CloudFlare Access Keycloak identity provider ID"
  value       = cloudflare_zero_trust_access_identity_provider.keycloak.id
}

output "protected_application_ids" {
  description = "Map of service name to CloudFlare Access application ID"
  value       = { for k, v in cloudflare_zero_trust_access_application.protected : k => v.id }
}
