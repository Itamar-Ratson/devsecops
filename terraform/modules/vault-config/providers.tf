provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

# Kubernetes provider is configured by the caller (Terragrunt)
# using the kubeconfig from the cluster module output
