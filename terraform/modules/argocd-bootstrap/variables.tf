variable "argocd_ssh_private_key" {
  description = "SSH private key for ArgoCD repository access"
  type        = string
  sensitive   = true
}

variable "git_repo_url" {
  description = "Git repository URL for ArgoCD"
  type        = string
}

variable "kubeconfig" {
  description = "Kubeconfig for accessing the Kubernetes cluster"
  type        = string
  sensitive   = true
}
