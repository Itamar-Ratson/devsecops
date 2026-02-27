# KinD cluster auth (where ArgoCD runs)
variable "kind_endpoint" {
  description = "KinD Kubernetes API server endpoint"
  type        = string
}

variable "kind_cluster_ca_certificate" {
  description = "KinD cluster CA certificate (PEM)"
  type        = string
  sensitive   = true
}

variable "kind_client_certificate" {
  description = "KinD client certificate for K8s auth"
  type        = string
  sensitive   = true
}

variable "kind_client_key" {
  description = "KinD client key for K8s auth"
  type        = string
  sensitive   = true
}

# EKS cluster details
variable "eks_cluster_endpoint" {
  description = "EKS cluster endpoint URL"
  type        = string
}

variable "eks_cluster_ca_data" {
  description = "Base64-encoded EKS cluster CA certificate"
  type        = string
  sensitive   = true
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "argocd_manager_token" {
  description = "Long-lived SA token for ArgoCD to manage EKS"
  type        = string
  sensitive   = true
}

# Git repo
variable "git_repo_url" {
  description = "Git repository URL"
  type        = string
}
