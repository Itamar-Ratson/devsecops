# ============================================================================
# Redis Secret (must exist before ArgoCD Helm install)
# ============================================================================
resource "random_password" "redis" {
  length  = 32
  special = false
}

resource "kubernetes_secret_v1" "argocd_redis" {
  metadata {
    name      = "argocd-redis"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }

  data = {
    auth = random_password.redis.result
  }
}

# ============================================================================
# ArgoCD Namespace
# ============================================================================
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

# ============================================================================
# Vault Transit Token Secret
# (ArgoCD deploys Vault into the secrets namespace — pre-create this secret
# so the vault pod can start. The secrets namespace is created by the
# cluster-bootstrap module via the sealed-secrets helm_release.)
# ============================================================================
resource "kubernetes_secret_v1" "vault_transit_token" {
  metadata {
    name      = "vault-transit-token"
    namespace = "secrets"
  }

  data = {
    VAULT_TOKEN = var.vault_root_token
  }
}

# ============================================================================
# ArgoCD Deploy Key (auto-generated + registered on GitHub)
# Skipped in CI (create_deploy_key = false) — public repo uses HTTPS.
# ============================================================================
resource "tls_private_key" "argocd_deploy_key" {
  count     = var.create_deploy_key ? 1 : 0
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "argocd" {
  count      = var.create_deploy_key ? 1 : 0
  title      = "ArgoCD (Terraform-managed)"
  repository = local.github_repo
  key        = tls_private_key.argocd_deploy_key[0].public_key_openssh
  read_only  = true
}

# ============================================================================
# ArgoCD Repository Credentials (SSH — local only)
# In CI (create_deploy_key = false), repo is public so ArgoCD clones via
# HTTPS without credentials.
# ============================================================================
resource "kubernetes_secret_v1" "argocd_repo_creds" {
  count = var.create_deploy_key ? 1 : 0

  metadata {
    name      = "argocd-repo-creds"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    type          = "git"
    url           = var.git_repo_url
    sshPrivateKey = tls_private_key.argocd_deploy_key[0].private_key_openssh
  }
}

# ============================================================================
# ArgoCD OIDC Secret (needed before VSO is available)
# ============================================================================
resource "kubernetes_secret_v1" "argocd_oidc" {
  metadata {
    name      = "argocd-oidc-secret"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    "oidc.keycloak.clientSecret" = var.argocd_oidc_client_secret
  }
}
