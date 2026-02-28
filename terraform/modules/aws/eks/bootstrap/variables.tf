variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_ca_data" {
  description = "Base64-encoded cluster CA certificate"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL (without https://)"
  type        = string
}
