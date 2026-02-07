# Service account for Vault's Kubernetes auth backend to call TokenReview API.
# Transit Vault is external to the cluster — it needs a JWT to validate
# service account tokens presented by VSO and other in-cluster workloads.

resource "kubernetes_service_account_v1" "vault_auth" {
  depends_on = [null_resource.wait_nodes]

  metadata {
    name      = "vault-auth"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "vault_auth" {
  metadata {
    name = "vault-auth-delegator"
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

resource "kubernetes_secret_v1" "vault_auth_token" {
  metadata {
    name      = "vault-auth-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.vault_auth.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}
