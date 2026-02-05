# --- From vault module outputs ---

variable "vault_address" {
  description = "Address of the Vault server"
  type        = string
}

variable "vault_token" {
  description = "Root token for Vault"
  type        = string
  sensitive   = true
}

variable "kubernetes_auth_path" {
  description = "Path to the Kubernetes auth backend in Vault"
  type        = string
}

variable "kv_mount_path" {
  description = "Path to the KV v2 secret engine in Vault"
  type        = string
}

# --- From cluster module outputs ---

variable "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  type        = string
}

variable "cluster_ca_cert" {
  description = "Kubernetes cluster CA certificate (PEM)"
  type        = string
}

variable "token_reviewer_jwt" {
  description = "Service account JWT for Vault to validate K8s tokens via TokenReview API"
  type        = string
  sensitive   = true
}

# --- From secrets.tfvars ---

variable "oidc_client_secrets" {
  description = "OIDC client secrets for various services"
  type        = map(string)
  sensitive   = true
}

variable "keycloak_admin" {
  description = "Keycloak administrator credentials"
  type = object({
    user     = string
    password = string
  })
  sensitive = true
}

variable "grafana_admin" {
  description = "Grafana administrator credentials"
  type = object({
    user     = string
    password = string
  })
  sensitive = true
}

variable "argocd_admin" {
  description = "ArgoCD administrator credentials"
  type = object({
    password_hash     = string
    server_secret_key = string
  })
  sensitive = true
}

variable "alertmanager_webhooks" {
  description = "Alertmanager webhook URLs for notifications"
  type = object({
    pagerduty_routing_key = optional(string, "")
    slack_critical        = optional(string, "")
    slack_warning         = optional(string, "")
  })
  default   = null
  sensitive = true
}
