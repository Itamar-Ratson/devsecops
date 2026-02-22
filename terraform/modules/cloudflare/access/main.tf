terraform {
  required_version = ">= 1.5"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ============================================================================
# Keycloak as OIDC Identity Provider
# ============================================================================

resource "cloudflare_zero_trust_access_identity_provider" "keycloak" {
  account_id = var.cloudflare_account_id
  name       = "Keycloak"
  type       = "oidc"

  config = {
    client_id     = var.keycloak_client_id
    client_secret = var.keycloak_client_secret
    auth_url      = "https://keycloak.${var.domain}/realms/devsecops/protocol/openid-connect/auth"
    token_url     = "https://keycloak.${var.domain}/realms/devsecops/protocol/openid-connect/token"
    certs_url     = "https://keycloak.${var.domain}/realms/devsecops/protocol/openid-connect/certs"
    scopes        = ["openid", "profile", "email", "groups"]
  }
}

# ============================================================================
# Access Applications — one per protected service
# Policies are inline (v5 provider has no application_id on the policy resource)
# ============================================================================

resource "cloudflare_zero_trust_access_application" "protected" {
  for_each = toset(var.protected_services)

  zone_id                   = var.cloudflare_zone_id
  name                      = each.key
  domain                    = "${each.key}.${var.domain}"
  session_duration          = var.session_duration
  type                      = "self_hosted"
  auto_redirect_to_identity = true
  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.keycloak.id]

  policies = [{
    name     = "Require Keycloak SSO"
    decision = "allow"
    include = [{
      login_method = {
        id = cloudflare_zero_trust_access_identity_provider.keycloak.id
      }
    }]
  }]
}
