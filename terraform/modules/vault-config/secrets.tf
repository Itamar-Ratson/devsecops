# ============================================================================
# Seed KV v2 secrets (pulled by VSO after ArgoCD deploys it)
# ============================================================================

resource "vault_kv_secret_v2" "oidc_clients" {
  mount = "secret"
  name  = "keycloak/oidc-clients"

  data_json = jsonencode({
    "argocd-client-secret"   = var.oidc_client_secrets["argocd"]
    "grafana-client-secret"  = var.oidc_client_secrets["grafana"]
    "vault-client-secret"    = var.oidc_client_secrets["vault"]
    "headlamp-client-secret" = var.oidc_client_secrets["headlamp"]
  })
}

resource "vault_kv_secret_v2" "keycloak_admin" {
  mount = "secret"
  name  = "keycloak/admin"

  data_json = jsonencode({
    "admin-user"     = var.keycloak_admin.username
    "admin-password" = var.keycloak_admin.password
  })
}

resource "vault_kv_secret_v2" "grafana_admin" {
  mount = "secret"
  name  = "monitoring/grafana"

  data_json = jsonencode({
    "admin-user"     = var.grafana_admin.username
    "admin-password" = var.grafana_admin.password
  })
}

resource "vault_kv_secret_v2" "alertmanager" {
  mount = "secret"
  name  = "monitoring/alertmanager"

  data_json = jsonencode({
    "pagerduty-routing-key"  = var.alertmanager_webhooks.pagerduty_routing_key
    "slack-critical-webhook" = var.alertmanager_webhooks.slack_critical_webhook
    "slack-warning-webhook"  = var.alertmanager_webhooks.slack_warning_webhook
  })
}

resource "vault_kv_secret_v2" "argocd_admin" {
  mount = "secret"
  name  = "argocd/admin"

  data_json = jsonencode({
    "admin.password"   = var.argocd_admin.password_hash
    "server.secretkey" = var.argocd_admin.server_secret_key
  })
}
