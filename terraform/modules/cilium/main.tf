# Cilium CNI Module
# Installs Cilium as the CNI for the cluster

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

variable "cilium_version" {
  description = "Cilium Helm chart version"
  type        = string
  default     = "1.16.5"
}

# Build Helm dependencies
resource "null_resource" "helm_dep_build" {
  provisioner "local-exec" {
    command     = "helm dependency build"
    working_dir = "${path.root}/../helm/cilium"
  }

  triggers = {
    always_run = timestamp()
  }
}

# Install Cilium via Helm
resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  chart      = "${path.root}/../helm/cilium"

  values = [
    file("${path.root}/../helm/ports.yaml"),
    file("${path.root}/../helm/cilium/values.yaml"),
  ]

  wait    = true
  timeout = 600

  depends_on = [null_resource.helm_dep_build]
}

# Wait for nodes to be ready
resource "null_resource" "wait_for_nodes" {
  depends_on = [helm_release.cilium]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Ready nodes --all --timeout=300s"
  }
}

output "cilium_installed" {
  description = "Whether Cilium was installed"
  value       = true
}
