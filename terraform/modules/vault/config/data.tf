# All secret values are read from AWS SSM Parameter Store.
# Parameters are seeded once by the admin via terraform/live/aws/ssm.

# -- OIDC client secrets -------------------------------------------------------
data "aws_ssm_parameter" "oidc_argocd" {
  name            = "/devsecops/oidc-argocd"
  with_decryption = true
}

data "aws_ssm_parameter" "oidc_grafana" {
  name            = "/devsecops/oidc-grafana"
  with_decryption = true
}

data "aws_ssm_parameter" "oidc_vault" {
  name            = "/devsecops/oidc-vault"
  with_decryption = true
}

data "aws_ssm_parameter" "oidc_headlamp" {
  name            = "/devsecops/oidc-headlamp"
  with_decryption = true
}

data "aws_ssm_parameter" "oidc_cloudflare_access" {
  name            = "/devsecops/oidc-cloudflare-access"
  with_decryption = true
}

# -- Keycloak -------------------------------------------------------------------
data "aws_ssm_parameter" "keycloak_admin_username" {
  name            = "/devsecops/keycloak-admin-username"
  with_decryption = true
}

data "aws_ssm_parameter" "keycloak_admin_password" {
  name            = "/devsecops/keycloak-admin-password"
  with_decryption = true
}

# -- Grafana --------------------------------------------------------------------
data "aws_ssm_parameter" "grafana_admin_username" {
  name            = "/devsecops/grafana-admin-username"
  with_decryption = true
}

data "aws_ssm_parameter" "grafana_admin_password" {
  name            = "/devsecops/grafana-admin-password"
  with_decryption = true
}

# -- ArgoCD admin ---------------------------------------------------------------
data "aws_ssm_parameter" "argocd_admin_password_hash" {
  name            = "/devsecops/argocd-admin-password-hash"
  with_decryption = true
}

data "aws_ssm_parameter" "argocd_server_secret_key" {
  name            = "/devsecops/argocd-server-secret-key"
  with_decryption = true
}

# -- Cloudflare -----------------------------------------------------------------
data "aws_ssm_parameter" "cloudflare_api_token" {
  name            = "/devsecops/cloudflare-api-token"
  with_decryption = true
}

# -- Alertmanager (optional; "DISABLED" sentinel -> converted to "" below) ------
data "aws_ssm_parameter" "alertmanager_pagerduty" {
  name            = "/devsecops/alertmanager-pagerduty-routing-key"
  with_decryption = true
}

data "aws_ssm_parameter" "alertmanager_slack_critical" {
  name            = "/devsecops/alertmanager-slack-critical-webhook"
  with_decryption = true
}

data "aws_ssm_parameter" "alertmanager_slack_warning" {
  name            = "/devsecops/alertmanager-slack-warning-webhook"
  with_decryption = true
}

# Convert "DISABLED" sentinel to empty string so downstream Vault/alertmanager
# config behaves the same as when the webhook was never set.
locals {
  alertmanager_pagerduty      = data.aws_ssm_parameter.alertmanager_pagerduty.value == "DISABLED" ? "" : data.aws_ssm_parameter.alertmanager_pagerduty.value
  alertmanager_slack_critical = data.aws_ssm_parameter.alertmanager_slack_critical.value == "DISABLED" ? "" : data.aws_ssm_parameter.alertmanager_slack_critical.value
  alertmanager_slack_warning  = data.aws_ssm_parameter.alertmanager_slack_warning.value == "DISABLED" ? "" : data.aws_ssm_parameter.alertmanager_slack_warning.value
}

# -- Tailscale OAuth (Kubernetes Operator) ------------------------------------
data "aws_ssm_parameter" "tailscale_oauth_client_id" {
  name            = "/devsecops/tailscale-oauth-client-id"
  with_decryption = true
}

data "aws_ssm_parameter" "tailscale_oauth_client_secret" {
  name            = "/devsecops/tailscale-oauth-client-secret"
  with_decryption = true
}
