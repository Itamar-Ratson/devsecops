variable "argocd_ssh_private_key" {
  description = "SSH private key for ArgoCD repository access"
  type        = string
  sensitive   = true
}

variable "git_repo_url" {
  description = "Git repository URL for ArgoCD"
  type        = string
}

variable "helm_values_dir" {
  description = "Absolute path to the helm/ directory containing chart values"
  type        = string
}

variable "kubeconfig" {
  description = "Kubeconfig for accessing the Kubernetes cluster"
  type        = string
  sensitive   = true
}
