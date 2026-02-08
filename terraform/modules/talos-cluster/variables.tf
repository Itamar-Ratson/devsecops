variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
  default     = "talos-dev"
}

variable "helm_values_dir" {
  description = "Absolute path to the helm/ directory containing chart values"
  type        = string
}

variable "controlplane_memory" {
  description = "Memory for control plane VM in MB"
  type        = number
  default     = 2048
}

variable "controlplane_vcpu" {
  description = "Number of vCPUs for control plane VM"
  type        = number
  default     = 2
}

variable "network_id" {
  description = "ID of the libvirt network"
  type        = string
}

variable "network_name" {
  description = "Name of the libvirt network"
  type        = string
}

variable "pod_cidr" {
  description = "CIDR block for Kubernetes pods"
  type        = string
  default     = "10.10.0.0/16"
}

variable "service_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "10.96.0.0/12"
}

variable "talos_version" {
  description = "Talos OS version"
  type        = string
  default     = "v1.12.1"
}

variable "vault_address" {
  description = "Address of the Vault server"
  type        = string
}

variable "vm_controlplane_ip" {
  description = "Static IP for control plane VM"
  type        = string
  default     = "192.168.100.10"
}

variable "vm_controlplane_mac" {
  description = "MAC address for control plane VM"
  type        = string
  default     = "52:54:00:00:01:10"
}

variable "vm_worker_ip" {
  description = "Static IP for worker VM"
  type        = string
  default     = "192.168.100.11"
}

variable "vm_worker_mac" {
  description = "MAC address for worker VM"
  type        = string
  default     = "52:54:00:00:01:11"
}

variable "worker_memory" {
  description = "Memory for worker VM in MB"
  type        = number
  default     = 4096
}

variable "worker_vcpu" {
  description = "Number of vCPUs for worker VM"
  type        = number
  default     = 2
}
