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

resource "vault_kv_secret_v2" "alertmanager_webhooks" {
  depends_on = [vault_mount.kv]
  count      = length(var.alertmanager_webhooks) > 0 ? 1 : 0

  mount = vault_mount.kv.path
  name  = "alertmanager/webhooks"

  data_json = jsonencode({
    pagerduty_routing_key = var.alertmanager_webhooks.pagerduty_routing_key
    slack_critical        = var.alertmanager_webhooks.slack_critical
    slack_warning         = var.alertmanager_webhooks.slack_warning
  })
}

resource "vault_kv_secret_v2" "argocd_admin" {
  depends_on = [vault_mount.kv]

  mount = vault_mount.kv.path
  name  = "argocd/admin"

  data_json = jsonencode({
    password_hash     = var.argocd_admin.password_hash
    server_secret_key = var.argocd_admin.server_secret_key
  })
}

resource "vault_kv_secret_v2" "grafana_admin" {
  depends_on = [vault_mount.kv]

  mount = vault_mount.kv.path
  name  = "grafana/admin"

  data_json = jsonencode({
    username = var.grafana_admin.user
    password = var.grafana_admin.password
  })
}

resource "vault_kv_secret_v2" "keycloak_admin" {
  depends_on = [vault_mount.kv]

  mount = vault_mount.kv.path
  name  = "keycloak/admin"

  data_json = jsonencode({
    username = var.keycloak_admin.user
    password = var.keycloak_admin.password
  })
}

resource "vault_kv_secret_v2" "oidc_clients" {
  depends_on = [vault_mount.kv]

  mount = vault_mount.kv.path
  name  = "oidc/clients"

  data_json = jsonencode({
    argocd   = var.oidc_client_secrets["argocd"]
    grafana  = var.oidc_client_secrets["grafana"]
    vault    = var.oidc_client_secrets["vault"]
    headlamp = var.oidc_client_secrets["headlamp"]
  })
}
