variable "vault_version" {
  description = "Vault Docker image tag"
  type        = string
  default     = "1.21.2"
}

variable "vault_root_token" {
  description = "Root token for Vault dev server"
  type        = string
  sensitive   = true
}

variable "container_name" {
  description = "Name for the Vault Docker container"
  type        = string
  default     = "vault-transit"
}

variable "host_port" {
  description = "Host port to map to Vault's 8200"
  type        = number
  default     = 8100
}
