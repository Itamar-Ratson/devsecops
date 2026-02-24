variable "vault_address" {
  description = "Vault API address (host-accessible)"
  type        = string
}

variable "vault_token" {
  description = "Vault root token"
  type        = string
  sensitive   = true
}

variable "control_plane_ip" {
  description = "KinD control plane IP on Docker network (for K8s auth config)"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "K8s cluster CA certificate (PEM, base64-decoded)"
  type        = string
  sensitive   = true
}

variable "token_reviewer_jwt" {
  description = "JWT for Vault to call K8s TokenReview API"
  type        = string
  sensitive   = true
}

variable "vso_allowed_namespaces" {
  description = "K8s namespaces allowed to authenticate via VSO role"
  type        = list(string)
  default = [
    "secrets",
    "observability",
    "argocd",
    "identity",
    "cloudflare",
    "cert-manager",
    "tailscale",
  ]
}
