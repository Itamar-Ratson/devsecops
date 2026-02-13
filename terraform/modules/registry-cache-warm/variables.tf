variable "cache_host_port" {
  description = "Host port for the registry cache (Zot)"
  type        = number
  default     = 5050
}

variable "cluster_name" {
  description = "KinD cluster name"
  type        = string
}
