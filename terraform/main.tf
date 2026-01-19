# Terraform configuration to replace setup.sh
# This manages the complete cluster bootstrap including:
# - Transit Vault (Docker container)
# - KinD cluster
# - Cilium CNI
# - Sealed Secrets
# - ArgoCD (GitOps controller)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.6"
    }
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
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Variables
variable "cluster_name" {
  description = "Name of the KinD cluster"
  type        = string
  default     = "k8s-dev"
}

variable "git_repo_url" {
  description = "Git repository URL for ArgoCD"
  type        = string
}

variable "vault_transit_token" {
  description = "Token for Transit Vault auto-unseal"
  type        = string
  sensitive   = true
}

variable "argocd_admin_password_hash" {
  description = "Bcrypt hash of ArgoCD admin password"
  type        = string
  sensitive   = true
}

variable "argocd_server_secret_key" {
  description = "ArgoCD server secret key"
  type        = string
  sensitive   = true
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "keycloak_admin_user" {
  description = "Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

variable "argocd_oidc_client_secret" {
  description = "ArgoCD OIDC client secret for Keycloak"
  type        = string
  sensitive   = true
}

variable "grafana_oidc_client_secret" {
  description = "Grafana OIDC client secret for Keycloak"
  type        = string
  sensitive   = true
}

variable "vault_oidc_client_secret" {
  description = "Vault OIDC client secret for Keycloak"
  type        = string
  sensitive   = true
}

variable "pagerduty_routing_key" {
  description = "PagerDuty routing key (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_critical_webhook" {
  description = "Slack webhook for critical alerts (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_warning_webhook" {
  description = "Slack webhook for warning alerts (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_key_path" {
  description = "Path to SSH key for ArgoCD deploy key"
  type        = string
  default     = "~/.ssh/argocd-deploy-key"
}

# Module: Transit Vault
module "transit_vault" {
  source = "./modules/transit-vault"

  vault_token = var.vault_transit_token
}

# Module: KinD Cluster
module "kind_cluster" {
  source = "./modules/kind-cluster"

  cluster_name      = var.cluster_name
  transit_vault_ip  = module.transit_vault.container_ip

  depends_on = [module.transit_vault]
}

# Configure providers after cluster is created
provider "kubernetes" {
  host                   = module.kind_cluster.cluster_endpoint
  cluster_ca_certificate = module.kind_cluster.cluster_ca_certificate
  client_certificate     = module.kind_cluster.client_certificate
  client_key             = module.kind_cluster.client_key
}

provider "helm" {
  kubernetes {
    host                   = module.kind_cluster.cluster_endpoint
    cluster_ca_certificate = module.kind_cluster.cluster_ca_certificate
    client_certificate     = module.kind_cluster.client_certificate
    client_key             = module.kind_cluster.client_key
  }
}

# Module: Cilium CNI
module "cilium" {
  source = "./modules/cilium"

  depends_on = [module.kind_cluster]
}

# Module: Sealed Secrets
module "sealed_secrets" {
  source = "./modules/sealed-secrets"

  depends_on = [module.cilium]
}

# Module: ArgoCD
module "argocd" {
  source = "./modules/argocd"

  git_repo_url               = var.git_repo_url
  ssh_key_path               = var.ssh_key_path
  admin_password_hash        = var.argocd_admin_password_hash
  server_secret_key          = var.argocd_server_secret_key
  oidc_client_secret         = var.argocd_oidc_client_secret
  vault_transit_token        = var.vault_transit_token
  grafana_admin_user         = var.grafana_admin_user
  grafana_admin_password     = var.grafana_admin_password
  keycloak_admin_user        = var.keycloak_admin_user
  keycloak_admin_password    = var.keycloak_admin_password
  grafana_oidc_client_secret = var.grafana_oidc_client_secret
  vault_oidc_client_secret   = var.vault_oidc_client_secret
  pagerduty_routing_key      = var.pagerduty_routing_key
  slack_critical_webhook     = var.slack_critical_webhook
  slack_warning_webhook      = var.slack_warning_webhook

  depends_on = [module.sealed_secrets]
}

# Outputs
output "cluster_name" {
  description = "Name of the KinD cluster"
  value       = var.cluster_name
}

output "argocd_url" {
  description = "ArgoCD UI URL"
  value       = "https://argocd.localhost"
}

output "transit_vault_ip" {
  description = "Transit Vault IP address"
  value       = module.transit_vault.container_ip
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = module.kind_cluster.kubeconfig_path
}
