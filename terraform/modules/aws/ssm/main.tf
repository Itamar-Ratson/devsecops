locals {
  prefix = "/devsecops"
}

# -- ArgoCD ---------------------------------------------------------------------

resource "aws_ssm_parameter" "github_token" {
  name      = "${local.prefix}/github-token"
  type      = "SecureString"
  value     = var.github_token
  overwrite = true
}

resource "aws_ssm_parameter" "oidc_argocd" {
  name      = "${local.prefix}/oidc-argocd"
  type      = "SecureString"
  value     = var.oidc_client_secrets["argocd"]
  overwrite = true
}

# -- vault/config OIDC ----------------------------------------------------------

resource "aws_ssm_parameter" "oidc_grafana" {
  name      = "${local.prefix}/oidc-grafana"
  type      = "SecureString"
  value     = var.oidc_client_secrets["grafana"]
  overwrite = true
}

resource "aws_ssm_parameter" "oidc_vault" {
  name      = "${local.prefix}/oidc-vault"
  type      = "SecureString"
  value     = var.oidc_client_secrets["vault"]
  overwrite = true
}

resource "aws_ssm_parameter" "oidc_headlamp" {
  name      = "${local.prefix}/oidc-headlamp"
  type      = "SecureString"
  value     = var.oidc_client_secrets["headlamp"]
  overwrite = true
}

# -- Keycloak -------------------------------------------------------------------

resource "aws_ssm_parameter" "keycloak_admin_username" {
  name      = "${local.prefix}/keycloak-admin-username"
  type      = "SecureString"
  value     = var.keycloak_admin.username
  overwrite = true
}

resource "aws_ssm_parameter" "keycloak_admin_password" {
  name      = "${local.prefix}/keycloak-admin-password"
  type      = "SecureString"
  value     = var.keycloak_admin.password
  overwrite = true
}

# -- Grafana --------------------------------------------------------------------

resource "aws_ssm_parameter" "grafana_admin_username" {
  name      = "${local.prefix}/grafana-admin-username"
  type      = "SecureString"
  value     = var.grafana_admin.username
  overwrite = true
}

resource "aws_ssm_parameter" "grafana_admin_password" {
  name      = "${local.prefix}/grafana-admin-password"
  type      = "SecureString"
  value     = var.grafana_admin.password
  overwrite = true
}

# -- ArgoCD admin ---------------------------------------------------------------

resource "aws_ssm_parameter" "argocd_admin_password_hash" {
  name      = "${local.prefix}/argocd-admin-password-hash"
  type      = "SecureString"
  value     = var.argocd_admin.password_hash
  overwrite = true
}

resource "aws_ssm_parameter" "argocd_server_secret_key" {
  name      = "${local.prefix}/argocd-server-secret-key"
  type      = "SecureString"
  value     = var.argocd_admin.server_secret_key
  overwrite = true
}

# -- Alertmanager webhooks (optional; use "DISABLED" to disable) ----------------

resource "aws_ssm_parameter" "alertmanager_pagerduty" {
  name      = "${local.prefix}/alertmanager-pagerduty-routing-key"
  type      = "SecureString"
  value     = var.alertmanager_webhooks.pagerduty_routing_key
  overwrite = true
}

resource "aws_ssm_parameter" "alertmanager_slack_critical" {
  name      = "${local.prefix}/alertmanager-slack-critical-webhook"
  type      = "SecureString"
  value     = var.alertmanager_webhooks.slack_critical_webhook
  overwrite = true
}

resource "aws_ssm_parameter" "alertmanager_slack_warning" {
  name      = "${local.prefix}/alertmanager-slack-warning-webhook"
  type      = "SecureString"
  value     = var.alertmanager_webhooks.slack_warning_webhook
  overwrite = true
}

# -- Let's Encrypt --------------------------------------------------------------

resource "aws_ssm_parameter" "letsencrypt_email" {
  name      = "${local.prefix}/letsencrypt-email"
  type      = "String"
  value     = var.letsencrypt_email
  overwrite = true
}

# -- CloudFlare -----------------------------------------------------------------

resource "aws_ssm_parameter" "cloudflare_api_token" {
  name      = "${local.prefix}/cloudflare-api-token"
  type      = "SecureString"
  value     = var.cloudflare_api_token
  overwrite = true
}

resource "aws_ssm_parameter" "cloudflare_account_id" {
  name      = "${local.prefix}/cloudflare-account-id"
  type      = "String"
  value     = var.cloudflare_account_id
  overwrite = true
}

resource "aws_ssm_parameter" "cloudflare_zone_id" {
  name      = "${local.prefix}/cloudflare-zone-id"
  type      = "String"
  value     = var.cloudflare_zone_id
  overwrite = true
}

resource "aws_ssm_parameter" "oidc_cloudflare_access" {
  name      = "${local.prefix}/oidc-cloudflare-access"
  type      = "SecureString"
  value     = var.oidc_client_secrets["cloudflare-access"]
  overwrite = true
}

# -- Tailscale -----------------------------------------------------------------

resource "aws_ssm_parameter" "tailscale_auth_key" {
  name      = "${local.prefix}/tailscale-auth-key"
  type      = "SecureString"
  value     = var.tailscale_auth_key
  overwrite = true
}

# -- Slack (CI/CD notifications) -----------------------------------------------

resource "aws_ssm_parameter" "slack_devops_webhook" {
  name      = "${local.prefix}/slack-devops-webhook"
  type      = "SecureString"
  value     = var.slack_devops_webhook
  overwrite = true
}

# -- Crossplane (AWS credentials for infrastructure provisioning) ---------------

resource "aws_ssm_parameter" "aws_access_key_id" {
  name      = "${local.prefix}/aws-access-key-id"
  type      = "SecureString"
  value     = var.aws_credentials.access_key_id
  overwrite = true
}

resource "aws_ssm_parameter" "aws_secret_access_key" {
  name      = "${local.prefix}/aws-secret-access-key"
  type      = "SecureString"
  value     = var.aws_credentials.secret_access_key
  overwrite = true
}
