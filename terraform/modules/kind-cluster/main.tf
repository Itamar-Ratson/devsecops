# KinD Cluster Module
# Creates a Kubernetes-in-Docker cluster with Cilium-ready configuration

terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.6"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

variable "cluster_name" {
  description = "Name of the KinD cluster"
  type        = string
  default     = "k8s-dev"
}

variable "transit_vault_ip" {
  description = "IP address of Transit Vault container"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "v1.29.2"
}

# Create KinD cluster
resource "kind_cluster" "this" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    networking {
      disable_default_cni = true  # We'll install Cilium
    }

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        <<-EOT
        kind: InitConfiguration
        nodeRegistration:
          taints:
            - key: "node-role.kubernetes.io/control-plane"
              effect: "NoSchedule"
        EOT
      ]
    }

    node {
      role = "worker"

      kubeadm_config_patches = [
        <<-EOT
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
        EOT
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }
  }
}

# Connect Transit Vault to KinD network
resource "null_resource" "connect_vault" {
  depends_on = [kind_cluster.this]

  provisioner "local-exec" {
    command = <<-EOT
      # Get KinD network subnet
      KIND_SUBNET=$(docker network inspect kind --format '{{range .IPAM.Config}}{{.Subnet}} {{end}}' | tr ' ' '\n' | grep "^172\." | head -1)
      TRANSIT_VAULT_IP=$(echo "$KIND_SUBNET" | cut -d'.' -f1-3).100

      # Connect Transit Vault to KinD network
      docker network connect --ip "$TRANSIT_VAULT_IP" kind vault-transit 2>/dev/null || \
        (docker network disconnect kind vault-transit 2>/dev/null || true; \
         docker network connect --ip "$TRANSIT_VAULT_IP" kind vault-transit)

      echo "Transit Vault connected to KinD network at $TRANSIT_VAULT_IP"
    EOT
  }
}

# Install Gateway API CRDs
resource "null_resource" "gateway_api_crds" {
  depends_on = [kind_cluster.this]

  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml"
  }
}

# Install Prometheus Operator CRDs
resource "null_resource" "prometheus_crds" {
  depends_on = [kind_cluster.this]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
      kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.87.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
    EOT
  }
}

# Install cert-manager CRDs
resource "null_resource" "certmanager_crds" {
  depends_on = [kind_cluster.this]

  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.2/cert-manager.crds.yaml"
  }
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = kind_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = kind_cluster.this.cluster_ca_certificate
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate"
  value       = kind_cluster.this.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key"
  value       = kind_cluster.this.client_key
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Path to kubeconfig"
  value       = kind_cluster.this.kubeconfig_path
}
