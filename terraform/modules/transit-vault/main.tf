provider "docker" {}

resource "docker_image" "vault" {
  name = "hashicorp/vault:${var.vault_version}"
}

resource "docker_volume" "vault_data" {
  name = "${var.container_name}-data"
}

resource "docker_container" "vault" {
  name  = var.container_name
  image = docker_image.vault.image_id

  env = [
    "VAULT_DEV_ROOT_TOKEN_ID=${var.vault_root_token}",
    "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200",
  ]

  ports {
    internal = 8200
    external = var.host_port
  }

  volumes {
    volume_name    = docker_volume.vault_data.name
    container_path = "/vault/data"
  }

  capabilities {
    add = ["IPC_LOCK"]
  }

  command = ["server", "-dev"]
  restart = "unless-stopped"

  must_run = true
  wait     = true

  healthcheck {
    test         = ["CMD", "vault", "status", "-address=http://127.0.0.1:8200"]
    interval     = "5s"
    timeout      = "3s"
    retries      = 12
    start_period = "5s"
  }
}

# Enable transit engine, create autounseal key, and enable KV v2
resource "null_resource" "vault_engines" {
  depends_on = [docker_container.vault]

  provisioner "local-exec" {
    environment = {
      VAULT_ADDR  = "http://127.0.0.1:${var.host_port}"
      VAULT_TOKEN = var.vault_root_token
    }
    command = <<-EOT
      # Wait for Vault to be ready
      for i in $(seq 1 30); do
        vault status && break
        sleep 1
      done

      # Enable transit engine + autounseal key
      vault secrets enable transit 2>/dev/null || true
      vault write -f transit/keys/autounseal 2>/dev/null || true

      # Enable KV v2 for static secrets
      vault secrets enable -path=secret kv-v2 2>/dev/null || true
    EOT
  }
}
