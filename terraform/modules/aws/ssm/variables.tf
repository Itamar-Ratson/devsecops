variable "github_token" {
  description = "GitHub personal access token (admin:repo_key scope) for deploy key management"
  type        = string
  sensitive   = true
}

variable "oidc_client_secrets" {
  description = "OIDC client secrets keyed by service name (argocd, grafana, vault, headlamp, cloudflare-access)"
  type        = map(string)
  sensitive   = true
}

variable "keycloak_admin" {
  description = "Keycloak admin credentials"
  type = object({
    username = string
    password = string
  })
  sensitive = true
}

variable "grafana_admin" {
  description = "Grafana admin credentials"
  type = object({
    username = string
    password = string
  })
  sensitive = true
}

variable "argocd_admin" {
  description = "ArgoCD admin credentials"
  type = object({
    password_hash     = string
    server_secret_key = string
  })
  sensitive = true
}

variable "cloudflare_api_token" {
  description = "CloudFlare API token (Tunnel + DNS + Access Edit permissions)"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "CloudFlare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "CloudFlare zone ID for itamarratson.com"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt ACME account (expiry notifications)"
  type        = string
}

variable "alertmanager_webhooks" {
  description = "Alertmanager webhook URLs. Use 'DISABLED' sentinel to disable a channel."
  type = object({
    pagerduty_routing_key  = optional(string, "DISABLED")
    slack_critical_webhook = optional(string, "DISABLED")
    slack_warning_webhook  = optional(string, "DISABLED")
  })
  default   = {}
  sensitive = true
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key for KinD subnet router (reusable + ephemeral + tag:k8s)"
  type        = string
  sensitive   = true
}

variable "slack_devops_webhook" {
  description = "Slack incoming webhook URL for the DevOps project channel (CI/CD notifications)"
  type        = string
  sensitive   = true
}
