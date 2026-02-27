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

variable "availability_zone" {
  description = "Single AZ — intentional for learning/dev. Production should use multiple AZs."
  type        = string
  default     = "eu-north-1a"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet (NAT Gateway)"
  type        = string
  default     = "10.50.0.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for private subnet (EKS workers). Sized for Cilium ENI mode — each pod consumes a VPC IP."
  type        = string
  default     = "10.50.16.0/20"
}

variable "cluster_name" {
  description = "EKS cluster name (for subnet tagging)"
  type        = string
  default     = "devsecops-eks"
}
