provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

# ============================================================================
# Kubernetes Auth Backend
# ============================================================================
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "this" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://${var.control_plane_ip}:6443"
  kubernetes_ca_cert = var.cluster_ca_certificate
  token_reviewer_jwt = var.token_reviewer_jwt
}

# Policy for VSO to read secrets
resource "vault_policy" "vso_reader" {
  name = "vso-reader"

  policy = <<-EOT
    path "secret/data/*" {
      capabilities = ["read"]
    }
    path "secret/metadata/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

# Role for VSO — only the controller SA in its own namespace
resource "vault_kubernetes_auth_backend_role" "vso" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vso"
  bound_service_account_names      = ["vault-secrets-operator-controller-manager"]
  bound_service_account_namespaces = ["vault-secrets-operator"]
  token_policies                   = [vault_policy.vso_reader.name]
  token_ttl                        = 3600
}
