# ArgoCD Module
# Installs ArgoCD and configures GitOps

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

variable "git_repo_url" {
  description = "Git repository URL"
  type        = string
}

variable "ssh_key_path" {
  description = "Path to SSH key"
  type        = string
}

variable "admin_password_hash" {
  description = "Bcrypt hash of admin password"
  type        = string
  sensitive   = true
}

variable "server_secret_key" {
  description = "Server secret key"
  type        = string
  sensitive   = true
}

variable "oidc_client_secret" {
  description = "OIDC client secret"
  type        = string
  sensitive   = true
}

variable "vault_transit_token" {
  description = "Vault transit token"
  type        = string
  sensitive   = true
}

variable "grafana_admin_user" {
  type = string
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}

variable "keycloak_admin_user" {
  type = string
}

variable "keycloak_admin_password" {
  type      = string
  sensitive = true
}

variable "grafana_oidc_client_secret" {
  type      = string
  sensitive = true
}

variable "vault_oidc_client_secret" {
  type      = string
  sensitive = true
}

variable "pagerduty_routing_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "slack_critical_webhook" {
  type      = string
  default   = ""
  sensitive = true
}

variable "slack_warning_webhook" {
  type      = string
  default   = ""
  sensitive = true
}

# Create ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Create Vault namespace
resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

# Create Keycloak namespace
resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = "keycloak"
  }
}

# Create Monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Generate SSH key if not exists
resource "tls_private_key" "argocd_deploy_key" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ssh_private_key" {
  content         = tls_private_key.argocd_deploy_key.private_key_openssh
  filename        = pathexpand(var.ssh_key_path)
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  content  = tls_private_key.argocd_deploy_key.public_key_openssh
  filename = "${pathexpand(var.ssh_key_path)}.pub"
}

# Create Vault secrets
resource "kubernetes_secret" "vault_transit_token" {
  metadata {
    name      = "vault-transit-token"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    VAULT_TOKEN = var.vault_transit_token
  }
}

resource "kubernetes_secret" "vault_bootstrap_secrets" {
  metadata {
    name      = "vault-bootstrap-secrets"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    "grafana-user"               = var.grafana_admin_user
    "grafana-password"           = var.grafana_admin_password
    "argocd-password-hash"       = var.admin_password_hash
    "argocd-server-secret-key"   = var.server_secret_key
    "pagerduty-routing-key"      = var.pagerduty_routing_key
    "slack-critical-webhook"     = var.slack_critical_webhook
    "slack-warning-webhook"      = var.slack_warning_webhook
    "keycloak-admin-user"        = var.keycloak_admin_user
    "keycloak-admin-password"    = var.keycloak_admin_password
    "argocd-oidc-client-secret"  = var.oidc_client_secret
    "grafana-oidc-client-secret" = var.grafana_oidc_client_secret
    "vault-oidc-client-secret"   = var.vault_oidc_client_secret
  }
}

# Create Keycloak secrets
resource "kubernetes_secret" "keycloak_admin_credentials" {
  metadata {
    name      = "keycloak-admin-credentials"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  data = {
    "admin-user"     = var.keycloak_admin_user
    "admin-password" = var.keycloak_admin_password
  }
}

resource "kubernetes_secret" "keycloak_oidc_clients" {
  metadata {
    name      = "keycloak-oidc-clients"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  data = {
    "argocd-client-secret"  = var.oidc_client_secret
    "grafana-client-secret" = var.grafana_oidc_client_secret
    "vault-client-secret"   = var.vault_oidc_client_secret
  }
}

# Create Monitoring secrets
resource "kubernetes_secret" "grafana_admin_credentials" {
  metadata {
    name      = "grafana-admin-credentials"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "admin-user"     = var.grafana_admin_user
    "admin-password" = var.grafana_admin_password
  }
}

resource "kubernetes_secret" "grafana_oidc_secret" {
  metadata {
    name      = "grafana-oidc-secret"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET" = var.grafana_oidc_client_secret
  }
}

resource "kubernetes_secret" "alertmanager_slack_webhooks" {
  metadata {
    name      = "alertmanager-slack-webhooks"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "pagerduty-routing-key"  = var.pagerduty_routing_key
    "slack-critical-webhook" = var.slack_critical_webhook
    "slack-warning-webhook"  = var.slack_warning_webhook
  }
}

# Create ArgoCD repo credentials sealed secret
resource "null_resource" "argocd_repo_creds" {
  depends_on = [local_sensitive_file.ssh_private_key]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl create secret generic argocd-repo-creds \
        --namespace argocd \
        --from-literal=type=git \
        --from-literal=url="${var.git_repo_url}" \
        --from-file=sshPrivateKey="${pathexpand(var.ssh_key_path)}" \
        --dry-run=client -o yaml | \
        kubectl label --local -f - argocd.argoproj.io/secret-type=repo-creds -o yaml | \
        kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets -o yaml | \
        kubectl apply -f -
    EOT
  }
}

# Build Helm dependencies
resource "null_resource" "helm_dep_build" {
  provisioner "local-exec" {
    command     = "helm dependency build"
    working_dir = "${path.root}/../helm/argocd"
  }

  triggers = {
    always_run = timestamp()
  }
}

# Install ArgoCD (GitOps disabled initially)
resource "helm_release" "argocd_initial" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  chart      = "${path.root}/../helm/argocd"

  values = [
    file("${path.root}/../helm/ports.yaml"),
    file("${path.root}/../helm/argocd/values.yaml"),
    file("${path.root}/../helm/argocd/values-argocd.yaml"),
  ]

  set {
    name  = "gitops.repoURL"
    value = var.git_repo_url
  }

  set {
    name  = "gitops.enabled"
    value = "false"
  }

  set {
    name  = "vaultSecrets.enabled"
    value = "false"
  }

  wait    = true
  timeout = 300

  depends_on = [
    null_resource.helm_dep_build,
    null_resource.argocd_repo_creds,
  ]
}

# Wait for ArgoCD server
resource "null_resource" "wait_for_argocd" {
  depends_on = [helm_release.argocd_initial]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=180s"
  }
}

# Patch argocd-secret with OIDC secret
resource "null_resource" "patch_oidc_secret" {
  depends_on = [null_resource.wait_for_argocd]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl patch secret argocd-secret -n argocd --type='json' -p="[
        {\"op\": \"add\", \"path\": \"/data/oidc.keycloak.clientSecret\", \"value\": \"$(echo -n '${var.oidc_client_secret}' | base64 -w0)\"}
      ]"
    EOT
  }
}

# Enable GitOps
resource "helm_release" "argocd_gitops" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  chart      = "${path.root}/../helm/argocd"

  values = [
    file("${path.root}/../helm/ports.yaml"),
    file("${path.root}/../helm/argocd/values.yaml"),
    file("${path.root}/../helm/argocd/values-argocd.yaml"),
  ]

  set {
    name  = "gitops.repoURL"
    value = var.git_repo_url
  }

  set {
    name  = "gitops.enabled"
    value = "true"
  }

  set {
    name  = "vaultSecrets.enabled"
    value = "false"
  }

  wait    = true
  timeout = 300

  depends_on = [null_resource.patch_oidc_secret]
}

output "argocd_installed" {
  description = "Whether ArgoCD was installed"
  value       = true
}

output "ssh_public_key" {
  description = "SSH public key for GitHub deploy key"
  value       = tls_private_key.argocd_deploy_key.public_key_openssh
}
