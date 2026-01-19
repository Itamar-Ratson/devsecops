# Cilium Cluster Mesh Module
# Creates multiple KinD clusters with Cilium Cluster Mesh connectivity
#
# This module is for testing multi-cluster scenarios. It creates:
# - Multiple KinD clusters on separate Docker networks
# - Cilium with Cluster Mesh enabled on each cluster
# - Cross-cluster connectivity via ClusterMesh API server

terraform {
  required_providers {
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
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

variable "cluster_count" {
  description = "Number of clusters to create for Cluster Mesh"
  type        = number
  default     = 2
}

variable "base_cluster_name" {
  description = "Base name for clusters (will be appended with number)"
  type        = string
  default     = "mesh-cluster"
}

# Create Docker networks for each cluster
resource "docker_network" "cluster_networks" {
  count  = var.cluster_count
  name   = "${var.base_cluster_name}-${count.index + 1}-net"
  driver = "bridge"

  ipam_config {
    subnet  = "172.${20 + count.index}.0.0/16"
    gateway = "172.${20 + count.index}.0.1"
  }
}

# Create KinD clusters
resource "kind_cluster" "clusters" {
  count          = var.cluster_count
  name           = "${var.base_cluster_name}-${count.index + 1}"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    networking {
      disable_default_cni = true
      pod_subnet          = "10.${count.index + 1}.0.0/16"
      service_subnet      = "10.${100 + count.index}.0.0/16"
    }

    node {
      role = "control-plane"
    }

    node {
      role = "worker"

      extra_port_mappings {
        container_port = 32379  # ClusterMesh API server
        host_port      = 32379 + count.index
        protocol       = "TCP"
      }
    }
  }
}

# Connect clusters to shared network for ClusterMesh connectivity
resource "docker_network" "mesh_network" {
  name   = "cilium-mesh"
  driver = "bridge"

  ipam_config {
    subnet  = "172.30.0.0/16"
    gateway = "172.30.0.1"
  }
}

resource "null_resource" "connect_clusters_to_mesh" {
  count      = var.cluster_count
  depends_on = [kind_cluster.clusters, docker_network.mesh_network]

  provisioner "local-exec" {
    command = <<-EOT
      # Connect control-plane node to mesh network
      docker network connect cilium-mesh ${var.base_cluster_name}-${count.index + 1}-control-plane 2>/dev/null || true
      # Connect worker node to mesh network
      docker network connect cilium-mesh ${var.base_cluster_name}-${count.index + 1}-worker 2>/dev/null || true
    EOT
  }
}

# Install Gateway API CRDs on each cluster
resource "null_resource" "gateway_api_crds" {
  count      = var.cluster_count
  depends_on = [kind_cluster.clusters]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl --context kind-${var.base_cluster_name}-${count.index + 1} \
        apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml
    EOT
  }
}

# Build Cilium Helm dependencies
resource "null_resource" "helm_dep_build" {
  provisioner "local-exec" {
    command     = "helm dependency build"
    working_dir = "${path.root}/../helm/cilium"
  }

  triggers = {
    always_run = timestamp()
  }
}

# Install Cilium with Cluster Mesh on each cluster
resource "null_resource" "install_cilium" {
  count      = var.cluster_count
  depends_on = [null_resource.helm_dep_build, null_resource.connect_clusters_to_mesh]

  provisioner "local-exec" {
    command = <<-EOT
      helm upgrade --install cilium ${path.root}/../helm/cilium \
        --kube-context kind-${var.base_cluster_name}-${count.index + 1} \
        -n kube-system \
        -f ${path.root}/../helm/ports.yaml \
        -f ${path.root}/../helm/cilium/values.yaml \
        -f ${path.root}/../helm/cilium/values-clustermesh.yaml \
        --set cilium.cluster.name=${var.base_cluster_name}-${count.index + 1} \
        --set cilium.cluster.id=${count.index + 1} \
        --wait --timeout 10m
    EOT
  }
}

# Wait for Cilium to be ready on all clusters
resource "null_resource" "wait_for_cilium" {
  count      = var.cluster_count
  depends_on = [null_resource.install_cilium]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl --context kind-${var.base_cluster_name}-${count.index + 1} \
        wait --for=condition=Ready nodes --all --timeout=300s
      kubectl --context kind-${var.base_cluster_name}-${count.index + 1} \
        -n kube-system wait --for=condition=Ready pod -l k8s-app=cilium --timeout=300s
    EOT
  }
}

# Enable Cluster Mesh connectivity between clusters using cilium CLI
resource "null_resource" "enable_cluster_mesh" {
  depends_on = [null_resource.wait_for_cilium]

  provisioner "local-exec" {
    command = <<-EOT
      # This requires the cilium CLI tool
      # Install with: curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz

      # Connect cluster1 to cluster2
      cilium clustermesh connect \
        --context kind-${var.base_cluster_name}-1 \
        --destination-context kind-${var.base_cluster_name}-2 \
        2>/dev/null || echo "Cluster mesh connection may need manual setup"
    EOT
  }
}

output "cluster_names" {
  description = "Names of created clusters"
  value       = [for i in range(var.cluster_count) : "${var.base_cluster_name}-${i + 1}"]
}

output "cluster_contexts" {
  description = "Kubectl contexts for created clusters"
  value       = [for i in range(var.cluster_count) : "kind-${var.base_cluster_name}-${i + 1}"]
}
