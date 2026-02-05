variable "network_bridge" {
  description = "Bridge name for the libvirt network"
  type        = string
  default     = "virbr-k8s"
}

variable "network_cidr" {
  description = "CIDR block for the libvirt network"
  type        = string
  default     = "192.168.100.0/24"
}

variable "network_name" {
  description = "Name of the libvirt network"
  type        = string
  default     = "k8s-dev"
}
