variable "zot_version" {
  description = "Zot Docker image tag"
  type        = string
  default     = "v2.1.14"
}

variable "container_name" {
  description = "Name for the Zot Docker container"
  type        = string
  default     = "registry-cache"
}

variable "host_port" {
  description = "Host port to map to Zot's 5000"
  type        = number
  default     = 5050
}
