variable "github_token" {
  description = "GitHub personal access token (admin:repo_key scope) for deploy key management"
  type        = string
  sensitive   = true
}

variable "oidc_client_secrets" {
  description = "OIDC client secrets keyed by service name (argocd, grafana, vault, headlamp)"
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
