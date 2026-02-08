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
  default     = "1.21.3"
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

variable "vm_mac" {
  description = "MAC address for the VM's network interface"
  type        = string
  default     = "52:54:00:00:01:02"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

variable "vm_disk_size" {
  description = "Disk size for Vault VM in bytes"
  type        = number
  default     = 10737418240 # 10 GB
}

variable "vm_vcpu" {
  description = "Number of vCPUs for Vault VM"
  type        = number
  default     = 1
}
