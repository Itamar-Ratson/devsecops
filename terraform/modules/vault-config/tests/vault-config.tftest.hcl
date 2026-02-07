variables {
  vault_address        = "http://192.168.100.2:8200"
  vault_token          = "root"
  kubernetes_auth_path = "kubernetes"
  kv_mount_path        = "secret"
  kubeconfig           = "/tmp/test-kubeconfig"
  cluster_endpoint     = "https://192.168.100.10:6443"
  cluster_ca_cert      = "mock-ca-cert"
  token_reviewer_jwt   = "mock-jwt"

  oidc_client_secrets = {
    argocd   = "test-secret-1"
    grafana  = "test-secret-2"
    vault    = "test-secret-3"
    headlamp = "test-secret-4"
  }

  keycloak_admin = {
    user     = "admin"
    password = "test-password"
  }

  grafana_admin = {
    user     = "admin"
    password = "test-password"
  }

  argocd_admin = {
    password_hash     = "test-hash"
    server_secret_key = "test-key"
  }
}

run "validate_k8s_auth_config" {
  command = plan

  assert {
    condition     = vault_kubernetes_auth_backend_config.main.backend == "kubernetes"
    error_message = "K8s auth backend path should be 'kubernetes'"
  }

  assert {
    condition     = vault_kubernetes_auth_backend_config.main.kubernetes_host == "https://192.168.100.10:6443"
    error_message = "K8s host should match cluster endpoint"
  }
}

run "validate_kv_secrets" {
  command = plan

  assert {
    condition     = vault_kv_secret_v2.oidc_clients.mount == "secret"
    error_message = "OIDC secrets should be in 'secret' mount"
  }

  assert {
    condition     = vault_kv_secret_v2.oidc_clients.name == "keycloak/oidc-clients"
    error_message = "OIDC secrets path should be 'keycloak/oidc-clients'"
  }

  assert {
    condition     = vault_kv_secret_v2.keycloak_admin.name == "keycloak/admin"
    error_message = "Keycloak admin path should be 'keycloak/admin'"
  }

  assert {
    condition     = vault_kv_secret_v2.grafana_admin.name == "monitoring/grafana"
    error_message = "Grafana admin path should be 'monitoring/grafana'"
  }

  assert {
    condition     = vault_kv_secret_v2.argocd_admin.name == "argocd/admin"
    error_message = "ArgoCD admin path should be 'argocd/admin'"
  }
}

run "validate_k8s_secrets" {
  command = plan

  assert {
    condition     = kubernetes_secret_v1.vault_transit_token.metadata[0].name == "vault-transit-token"
    error_message = "Vault transit token secret should be named 'vault-transit-token'"
  }

  assert {
    condition     = kubernetes_secret_v1.vault_transit_token.metadata[0].namespace == "vault"
    error_message = "Vault transit token should be in 'vault' namespace"
  }

  assert {
    condition     = kubernetes_secret_v1.argocd_oidc_secret.metadata[0].name == "argocd-oidc-secret"
    error_message = "ArgoCD OIDC secret should be named 'argocd-oidc-secret'"
  }

  assert {
    condition     = kubernetes_secret_v1.argocd_oidc_secret.metadata[0].namespace == "argocd"
    error_message = "ArgoCD OIDC secret should be in 'argocd' namespace"
  }
}
