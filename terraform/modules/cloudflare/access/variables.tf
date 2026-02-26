variable "cloudflare_api_token" {
  description = "CloudFlare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "CloudFlare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "CloudFlare zone ID"
  type        = string
}

variable "domain" {
  description = "Base domain name"
  type        = string
  default     = "itamarratson.com"
}

variable "keycloak_client_id" {
  description = "Keycloak OIDC client ID for CloudFlare Access"
  type        = string
  default     = "cloudflare-access"
}

variable "keycloak_client_secret" {
  description = "Keycloak OIDC client secret for CloudFlare Access"
  type        = string
  sensitive   = true
}

variable "protected_services" {
  description = "Service subdomain prefixes that require CloudFlare Access authentication"
  type        = list(string)
  # Excluded: echo (public demo), juice-shop (public demo), keycloak (needs unauthenticated access for OIDC flows)
  default = [
    "grafana",
    "argocd",
    "vault",
    "headlamp",
    "kafka-ui",
    "eks-echo",
  ]
}

variable "session_duration" {
  description = "CloudFlare Access session duration"
  type        = string
  default     = "24h"
}
