variable "alertmanager_webhooks" {
  description = "Alertmanager webhook URLs for notifications"
  type = object({
    pagerduty_routing_key = optional(string, "")
    slack_critical        = optional(string, "")
    slack_warning         = optional(string, "")
  })
  default   = {}
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

variable "grafana_admin" {
  description = "Grafana administrator credentials"
  type = object({
    user     = string
    password = string
  })
  sensitive = true
}

variable "keycloak_admin" {
  description = "Keycloak administrator credentials"
  type = object({
    user     = string
    password = string
  })
  sensitive = true
}

variable "network_id" {
  description = "ID of the libvirt network to attach to"
  type        = string
}

variable "network_name" {
  description = "Name of the libvirt network"
  type        = string
}

variable "oidc_client_secrets" {
  description = "OIDC client secrets for various services"
  type        = map(string)
  sensitive   = true
}

variable "vault_version" {
  description = "Vault version to install"
  type        = string
  default     = "1.15.0"
}

variable "vm_ip" {
  description = "Static IP address for Vault VM"
  type        = string
  default     = "192.168.100.2"
}

variable "vm_memory" {
  description = "Memory for Vault VM in MB"
  type        = number
  default     = 512
}

variable "vm_name" {
  description = "Name of the Vault VM"
  type        = string
  default     = "transit-vault"
}

variable "vm_vcpu" {
  description = "Number of vCPUs for Vault VM"
  type        = number
  default     = 1
}
