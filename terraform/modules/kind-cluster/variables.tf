variable "cluster_name" {
  description = "KinD cluster name"
  type        = string
  default     = "k8s-dev"
}

variable "vault_container_name" {
  description = "Name of the Transit Vault Docker container to connect to the KinD network"
  type        = string
}

variable "vault_container_id" {
  description = "Docker container ID of Transit Vault (triggers network reconnect on replacement)"
  type        = string
}
