variable "endpoint" {
  description = "Kubernetes API server endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Cluster CA certificate (PEM)"
  type        = string
  sensitive   = true
}

variable "client_certificate" {
  description = "Client certificate for K8s auth"
  type        = string
  sensitive   = true
}

variable "client_key" {
  description = "Client key for K8s auth"
  type        = string
  sensitive   = true
}

variable "helm_values_dir" {
  description = "Absolute path to the helm/ directory"
  type        = string
}

variable "git_repo_url" {
  description = "Git repository URL (SSH format)"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token for managing deploy keys"
  type        = string
  sensitive   = true
}

variable "vault_root_token" {
  description = "Vault transit token for auto-unseal secret"
  type        = string
  sensitive   = true
}

variable "argocd_oidc_client_secret" {
  description = "OIDC client secret for ArgoCD (from Keycloak)"
  type        = string
  sensitive   = true
}

variable "vault_cluster_ip" {
  description = "Transit Vault IP on the KinD Docker network"
  type        = string
}

variable "cache_cluster_ip" {
  description = "Registry cache IP on the KinD Docker network"
  type        = string
}
