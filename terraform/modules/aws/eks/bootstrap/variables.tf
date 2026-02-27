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

variable "helm_values_dir" {
  description = "Absolute path to the helm/ directory containing chart values"
  type        = string
}

variable "gateway_api_version" {
  description = "Gateway API CRD version"
  type        = string
  default     = "v1.4.0"
}

variable "prometheus_operator_version" {
  description = "Prometheus Operator CRD version"
  type        = string
  default     = "v0.88.1"
}
