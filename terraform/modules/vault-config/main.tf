# Post-cluster Vault configuration
# This module runs AFTER both the Vault VM and the Talos cluster exist.
# It configures Vault's Kubernetes auth backend (which needs cluster data)
# and seeds KV secrets from secrets.tfvars.

# Configure Kubernetes auth backend — tells Vault HOW to validate K8s SA tokens.
# This was the circular dependency: it needs the cluster CA cert and API endpoint,
# but the cluster depends on the Vault VM for transit autounseal.
# Solved by splitting into a separate post-cluster module.
resource "vault_kubernetes_auth_backend_config" "main" {
  backend            = var.kubernetes_auth_path
  kubernetes_host    = var.cluster_endpoint
  kubernetes_ca_cert = var.cluster_ca_cert
  token_reviewer_jwt = var.token_reviewer_jwt
}

# Create vault-transit-token K8s secret for in-cluster Vault auto-unseal
resource "kubernetes_secret" "vault_transit_token" {
  metadata {
    name      = "vault-transit-token"
    namespace = "vault"
  }

  data = {
    VAULT_TOKEN = var.vault_token
  }
}

# Create argocd-oidc-secret for ArgoCD bootstrap (before VSO takes over in Wave 2)
resource "kubernetes_secret" "argocd_oidc_secret" {
  metadata {
    name      = "argocd-oidc-secret"
    namespace = "argocd"
  }

  data = {
    "oidc.keycloak.clientSecret" = var.oidc_client_secrets["argocd"]
  }
}

# Seed KV secrets from secrets.tfvars
resource "vault_kv_secret_v2" "oidc_clients" {
  mount = var.kv_mount_path
  name  = "keycloak/oidc-clients"

  data_json = jsonencode({
    "argocd-client-secret"   = var.oidc_client_secrets["argocd"]
    "grafana-client-secret"  = var.oidc_client_secrets["grafana"]
    "vault-client-secret"    = var.oidc_client_secrets["vault"]
    "headlamp-client-secret" = var.oidc_client_secrets["headlamp"]
  })
}

resource "vault_kv_secret_v2" "keycloak_admin" {
  mount = var.kv_mount_path
  name  = "keycloak/admin"

  data_json = jsonencode({
    "admin-user"     = var.keycloak_admin.user
    "admin-password" = var.keycloak_admin.password
  })
}

resource "vault_kv_secret_v2" "grafana_admin" {
  mount = var.kv_mount_path
  name  = "monitoring/grafana"

  data_json = jsonencode({
    "admin-user"     = var.grafana_admin.user
    "admin-password" = var.grafana_admin.password
  })
}

resource "vault_kv_secret_v2" "alertmanager_webhooks" {
  count = var.alertmanager_webhooks != null ? 1 : 0

  mount = var.kv_mount_path
  name  = "monitoring/alertmanager"

  data_json = jsonencode({
    "pagerduty-routing-key"  = var.alertmanager_webhooks.pagerduty_routing_key
    "slack-critical-webhook" = var.alertmanager_webhooks.slack_critical
    "slack-warning-webhook"  = var.alertmanager_webhooks.slack_warning
  })
}

resource "vault_kv_secret_v2" "argocd_admin" {
  mount = var.kv_mount_path
  name  = "argocd/admin"

  data_json = jsonencode({
    "admin.password"   = var.argocd_admin.password_hash
    "admin.passwordMtime" = formatdate("YYYY-MM-DD'T'HH:mm:ss'Z'", timestamp())
    "server.secretkey" = var.argocd_admin.server_secret_key
  })

  lifecycle {
    ignore_changes = [data_json]
  }
}
