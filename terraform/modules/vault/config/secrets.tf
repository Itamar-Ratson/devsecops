# ============================================================================
# Seed KV v2 secrets (pulled by VSO after ArgoCD deploys it)
# All secret values are read from AWS SSM Parameter Store (see data.tf).
# ============================================================================

resource "vault_kv_secret_v2" "oidc_clients" {
  mount = "secret"
  name  = "keycloak/oidc-clients"

  data_json = jsonencode({
    "argocd-client-secret"            = data.aws_ssm_parameter.oidc_argocd.value
    "grafana-client-secret"           = data.aws_ssm_parameter.oidc_grafana.value
    "vault-client-secret"             = data.aws_ssm_parameter.oidc_vault.value
    "headlamp-client-secret"          = data.aws_ssm_parameter.oidc_headlamp.value
    "cloudflare-access-client-secret" = data.aws_ssm_parameter.oidc_cloudflare_access.value
  })
}

resource "vault_kv_secret_v2" "keycloak_admin" {
  mount = "secret"
  name  = "keycloak/admin"

  data_json = jsonencode({
    "admin-user"     = data.aws_ssm_parameter.keycloak_admin_username.value
    "admin-password" = data.aws_ssm_parameter.keycloak_admin_password.value
  })
}

resource "vault_kv_secret_v2" "grafana_admin" {
  mount = "secret"
  name  = "monitoring/grafana"

  data_json = jsonencode({
    "admin-user"     = data.aws_ssm_parameter.grafana_admin_username.value
    "admin-password" = data.aws_ssm_parameter.grafana_admin_password.value
  })
}

resource "vault_kv_secret_v2" "alertmanager" {
  mount = "secret"
  name  = "monitoring/alertmanager"

  data_json = jsonencode({
    "pagerduty-routing-key"  = local.alertmanager_pagerduty
    "slack-critical-webhook" = local.alertmanager_slack_critical
    "slack-warning-webhook"  = local.alertmanager_slack_warning
  })
}

resource "vault_kv_secret_v2" "cloudflare_api_token" {
  mount = "secret"
  name  = "cloudflare/api-token"

  data_json = jsonencode({
    "api-token" = data.aws_ssm_parameter.cloudflare_api_token.value
  })
}

resource "vault_kv_secret_v2" "argocd_admin" {
  mount = "secret"
  name  = "argocd/admin"

  data_json = jsonencode({
    "admin.password"   = data.aws_ssm_parameter.argocd_admin_password_hash.value
    "server.secretkey" = data.aws_ssm_parameter.argocd_server_secret_key.value
  })
}
