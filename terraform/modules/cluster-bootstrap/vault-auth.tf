# ============================================================================
# Vault TokenReviewer ServiceAccount
# Transit Vault (external) needs this to validate K8s JWTs
# ============================================================================
resource "kubernetes_service_account_v1" "vault_auth" {
  metadata {
    name      = "vault-auth"
    namespace = "kube-system"
  }

  depends_on = [null_resource.wait_nodes_ready]
}

resource "kubernetes_secret_v1" "vault_auth_token" {
  metadata {
    name      = "vault-auth-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.vault_auth.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"

  depends_on = [kubernetes_service_account_v1.vault_auth]
}

resource "kubernetes_cluster_role_binding" "vault_auth_tokenreview" {
  metadata {
    name = "vault-auth-tokenreview"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.vault_auth.metadata[0].name
    namespace = "kube-system"
  }
}
