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
  description = "CloudFlare zone ID for the domain"
  type        = string
}

variable "tunnel_name" {
  description = "Name for the CloudFlare tunnel"
  type        = string
  default     = "devsecops-kind"
}

variable "services" {
  description = "List of service subdomain prefixes to create CNAME records for"
  type        = list(string)
  default = [
    "grafana",
    "argocd",
    "vault",
    "keycloak",
    "headlamp",
    "kafka-ui",
    "juice-shop",
    "echo",
  ]
}

variable "vault_address" {
  description = "Vault API address"
  type        = string
}

variable "vault_token" {
  description = "Vault root token"
  type        = string
  sensitive   = true
}

variable "ssm_parameter_path" {
  description = "SSM parameter path for storing the tunnel token (for ESO on EKS)"
  type        = string
  default     = "/devsecops/cloudflare-tunnel-token"
}
