variable "cloudflare_api_token" {
  description = "CloudFlare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "CloudFlare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "CloudFlare zone ID for the domain"
  type        = string
}

variable "tunnel_name" {
  description = "Name for the CloudFlare tunnel"
  type        = string
  default     = "devsecops-eks"
}

variable "services" {
  description = "List of service subdomain prefixes to create CNAME records for"
  type        = list(string)
  default     = ["eks-echo"]
}

variable "ssm_parameter_path" {
  description = "AWS SSM parameter path to store the tunnel token"
  type        = string
  default     = "/devsecops/cloudflare-eks-tunnel-token"
}
