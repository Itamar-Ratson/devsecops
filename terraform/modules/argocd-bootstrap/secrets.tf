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
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  data = {
    auth = random_password.redis.result
  }
}

# ============================================================================
# ArgoCD Namespace
# ============================================================================
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# ============================================================================
# Vault Namespace + Transit Token Secret
# (ArgoCD Wave 2 deploys Vault — it needs this secret pre-created)
# ============================================================================
resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_secret_v1" "vault_transit_token" {
  metadata {
    name      = "vault-transit-token"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    VAULT_TOKEN = var.vault_root_token
  }
}

# ============================================================================
# ArgoCD Repository Credentials
# Plain K8s Secret with ArgoCD label — no need for SealedSecret since
# Terraform manages this (not stored in git, encrypted in HCP Terraform state)
# ============================================================================
resource "kubernetes_secret_v1" "argocd_repo_creds" {
  metadata {
    name      = "argocd-repo-creds"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    type          = "git"
    url           = var.git_repo_url
    sshPrivateKey = var.argocd_ssh_private_key
  }
}

# ============================================================================
# ArgoCD OIDC Secret (needed before VSO is available)
# ============================================================================
resource "kubernetes_secret_v1" "argocd_oidc" {
  metadata {
    name      = "argocd-oidc-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    "oidc.keycloak.clientSecret" = var.argocd_oidc_client_secret
  }
}
