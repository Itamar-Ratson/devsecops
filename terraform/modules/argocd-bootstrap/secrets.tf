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
# ArgoCD Repository Credentials (sealed via kubeseal)
# ============================================================================
resource "null_resource" "argocd_repo_creds" {
  depends_on = [kubernetes_namespace.argocd]

  triggers = {
    repo_url = var.git_repo_url
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG   = local_sensitive_file.kubeconfig.filename
      SSH_PRIV_KEY = var.argocd_ssh_private_key
      GIT_REPO_URL = var.git_repo_url
    }
    command = <<-EOT
      # Write SSH key to temp file
      TMPKEY=$(mktemp)
      echo "$SSH_PRIV_KEY" > "$TMPKEY"

      # Create secret, label it, seal it, apply it
      kubectl create secret generic argocd-repo-creds \
        --namespace argocd \
        --from-literal=type=git \
        --from-literal=url="$GIT_REPO_URL" \
        --from-file=sshPrivateKey="$TMPKEY" \
        --dry-run=client -o yaml | \
      kubectl label --local -f - argocd.argoproj.io/secret-type=repo-creds -o yaml | \
      kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets -o yaml | \
      kubectl apply -f -

      rm -f "$TMPKEY"
    EOT
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
