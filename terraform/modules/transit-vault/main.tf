# Transit Vault Module
# Manages the Docker container for Vault transit auto-unseal

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

variable "vault_token" {
  description = "Root token for Vault"
  type        = string
  sensitive   = true
}

variable "vault_version" {
  description = "Vault Docker image version"
  type        = string
  default     = "1.15"
}

# Docker provider configuration
provider "docker" {}

# Pull Vault image
resource "docker_image" "vault" {
  name         = "hashicorp/vault:${var.vault_version}"
  keep_locally = true
}

# Create Docker network for Transit Vault
resource "docker_network" "vault" {
  name   = "vault-transit"
  driver = "bridge"

  ipam_config {
    subnet  = "172.19.0.0/16"
    gateway = "172.19.0.1"
  }
}

# Create Transit Vault container
resource "docker_container" "vault_transit" {
  name  = "vault-transit"
  image = docker_image.vault.image_id

  env = [
    "VAULT_DEV_ROOT_TOKEN_ID=${var.vault_token}",
    "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200",
  ]

  ports {
    internal = 8200
    external = 8200
  }

  networks_advanced {
    name         = docker_network.vault.name
    ipv4_address = "172.19.0.100"
  }

  capabilities {
    add = ["IPC_LOCK"]
  }

  restart = "unless-stopped"

  healthcheck {
    test         = ["CMD", "vault", "status"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }

  # Wait for container to be healthy
  wait = true
}

# Initialize transit secrets engine
resource "null_resource" "init_transit" {
  depends_on = [docker_container.vault_transit]

  provisioner "local-exec" {
    command = <<-EOT
      sleep 5
      docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=${var.vault_token} vault-transit \
        vault secrets enable transit 2>/dev/null || true
      docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=${var.vault_token} vault-transit \
        vault write -f transit/keys/autounseal 2>/dev/null || true
    EOT
  }
}

output "container_ip" {
  description = "IP address of the Transit Vault container"
  value       = "172.19.0.100"
}

output "container_id" {
  description = "ID of the Transit Vault container"
  value       = docker_container.vault_transit.id
}
