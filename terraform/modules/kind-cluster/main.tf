provider "kind" {}
provider "docker" {}

resource "kind_cluster" "this" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    networking {
      disable_default_cni = true
    }

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        <<-PATCH
        kind: InitConfiguration
        nodeRegistration:
          taints:
            - key: "node-role.kubernetes.io/control-plane"
              effect: "NoSchedule"
        PATCH
      ]
    }

    node {
      role = "worker"

      kubeadm_config_patches = [
        <<-PATCH
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
        PATCH
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
        listen_address = "0.0.0.0"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
        listen_address = "0.0.0.0"
      }
    }
  }
}

# Discover the KinD Docker network to get the subnet
data "docker_network" "kind" {
  name = "kind"

  depends_on = [kind_cluster.this]
}

# Connect Vault container to KinD network with a static IP
# The static IP is the .100 address on the KinD subnet
locals {
  # KinD network subnet looks like "172.X.0.0/16" — extract the first two octets
  kind_subnet       = [for s in data.docker_network.kind.ipam_config : s.subnet if can(regex("^172\\.", s.subnet))][0]
  kind_subnet_parts = split(".", local.kind_subnet)
  vault_cluster_ip  = "${local.kind_subnet_parts[0]}.${local.kind_subnet_parts[1]}.0.100"
}

resource "null_resource" "connect_vault_to_kind" {
  depends_on = [kind_cluster.this]

  triggers = {
    vault_container    = var.vault_container_name
    vault_container_id = var.vault_container_id
    cluster_name       = kind_cluster.this.name
    vault_ip           = local.vault_cluster_ip
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Disconnect first if already connected (idempotent)
      docker network disconnect kind ${var.vault_container_name} 2>/dev/null || true
      # Connect with static IP
      docker network connect --ip ${local.vault_cluster_ip} kind ${var.vault_container_name}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "docker network disconnect kind ${self.triggers.vault_container} 2>/dev/null || true"
  }
}

# Get control plane internal IP for Vault K8s auth config
data "external" "control_plane_ip" {
  program = ["bash", "-c", <<-EOT
    IP=$(docker inspect ${var.cluster_name}-control-plane --format '{{.NetworkSettings.Networks.kind.IPAddress}}')
    echo "{\"ip\": \"$IP\"}"
  EOT
  ]

  depends_on = [kind_cluster.this]
}
