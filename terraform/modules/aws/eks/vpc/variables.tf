variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "devsecops-eks"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.50.0.0/16"
}

variable "availability_zones" {
  description = "AZs for subnets. EKS requires at least 2 AZs for the control plane. Workers use only the first AZ (learning/dev)."
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (one per AZ). Second AZ is minimal — only needed to satisfy EKS multi-AZ requirement."
  type        = list(string)
  default     = ["10.50.0.0/24", "10.50.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (one per AZ). First is sized for Cilium ENI mode (each pod consumes a VPC IP). Second is minimal."
  type        = list(string)
  default     = ["10.50.16.0/20", "10.50.32.0/24"]
}

variable "cluster_name" {
  description = "EKS cluster name (for subnet tagging)"
  type        = string
  default     = "devsecops-eks"
}
