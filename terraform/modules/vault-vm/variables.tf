variable "network_id" {
  description = "ID of the libvirt network to attach to"
  type        = string
}

variable "network_name" {
  description = "Name of the libvirt network"
  type        = string
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
