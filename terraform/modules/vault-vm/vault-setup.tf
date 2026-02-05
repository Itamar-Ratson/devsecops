# Pre-cluster Vault configuration
# These resources don't need the Kubernetes cluster to exist.
# K8s auth config and KV secret seeding are in the vault-config module (post-cluster).

resource "vault_mount" "kv" {
  depends_on = [null_resource.wait_for_vault]

  path        = "secret"
  type        = "kv-v2"
  description = "KV v2 secret engine"
}

resource "vault_mount" "transit" {
  depends_on = [null_resource.wait_for_vault]

  path        = "transit"
  type        = "transit"
  description = "Transit engine for Kubernetes Vault autounseal"
}

resource "vault_transit_secret_backend_key" "autounseal" {
  depends_on = [vault_mount.transit]

  backend          = vault_mount.transit.path
  name             = "autounseal"
  deletion_allowed = true
}

resource "vault_auth_backend" "kubernetes" {
  depends_on = [null_resource.wait_for_vault]

  type = "kubernetes"
  path = "kubernetes"
}

resource "vault_policy" "vso_reader" {
  depends_on = [null_resource.wait_for_vault]

  name = "vso-reader"

  policy = <<EOT
path "secret/data/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/*" {
  capabilities = ["list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "vso" {
  depends_on = [
    vault_auth_backend.kubernetes,
    vault_policy.vso_reader
  ]

  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vso"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["monitoring", "argocd", "keycloak", "vault", "kube-system"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.vso_reader.name]
}
