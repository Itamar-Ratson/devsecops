variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "devsecops-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.35"
}

variable "vpc_id" {
  description = "VPC ID from VPC module"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS workers"
  type        = list(string)
}

variable "instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Capacity type for the managed node group. SPOT is intentional for learning/dev — production should use ON_DEMAND or mixed."
  type        = string
  default     = "SPOT"
}

variable "allowed_public_cidrs" {
  description = "CIDRs allowed to reach the EKS public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
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
