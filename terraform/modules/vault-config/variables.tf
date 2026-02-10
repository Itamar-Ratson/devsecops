variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vault_address" {
  description = "Vault API address (host-accessible)"
  type        = string
}

variable "vault_token" {
  description = "Vault root token"
  type        = string
  sensitive   = true
}

variable "control_plane_ip" {
  description = "KinD control plane IP on Docker network (for K8s auth config)"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "K8s cluster CA certificate (PEM, base64-decoded)"
  type        = string
  sensitive   = true
}

variable "token_reviewer_jwt" {
  description = "JWT for Vault to call K8s TokenReview API"
  type        = string
  sensitive   = true
}

variable "oidc_client_secrets" {
  description = "OIDC client secrets keyed by service name"
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
  description = "Alertmanager webhook URLs (optional)"
  type = object({
    pagerduty_routing_key  = optional(string, "")
    slack_critical_webhook = optional(string, "")
    slack_warning_webhook  = optional(string, "")
  })
  default   = {}
  sensitive = true
}

variable "vso_allowed_namespaces" {
  description = "K8s namespaces allowed to authenticate via VSO role"
  type        = list(string)
  default = [
    "vault-secrets-operator",
    "monitoring",
    "argocd",
    "keycloak",
    "vault",
    "headlamp",
    "kube-oidc-proxy",
  ]
}
