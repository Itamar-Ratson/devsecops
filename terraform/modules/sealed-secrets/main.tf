# Sealed Secrets Module
# Installs Sealed Secrets controller for encrypting secrets

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
  }
}

# Create namespace
resource "kubernetes_namespace" "sealed_secrets" {
  metadata {
    name = "sealed-secrets"
  }
}

# Build Helm dependencies
resource "null_resource" "helm_dep_build" {
  provisioner "local-exec" {
    command     = "helm dependency build"
    working_dir = "${path.root}/../helm/sealed-secrets"
  }

  triggers = {
    always_run = timestamp()
  }
}

# Install Sealed Secrets via Helm
resource "helm_release" "sealed_secrets" {
  name       = "sealed-secrets"
  namespace  = kubernetes_namespace.sealed_secrets.metadata[0].name
  chart      = "${path.root}/../helm/sealed-secrets"

  values = [
    file("${path.root}/../helm/ports.yaml"),
  ]

  wait    = true
  timeout = 300

  depends_on = [null_resource.helm_dep_build]
}

# Wait for controller to be ready
resource "null_resource" "wait_for_controller" {
  depends_on = [helm_release.sealed_secrets]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Available deployment/sealed-secrets -n sealed-secrets --timeout=120s"
  }
}

output "sealed_secrets_installed" {
  description = "Whether Sealed Secrets was installed"
  value       = true
}
