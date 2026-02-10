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

# Vault provider — connects to the transit vault container via host port
provider "vault" {
  address = "http://127.0.0.1:${var.host_port}"
  token   = var.vault_root_token
}

# Enable transit engine for auto-unseal
resource "vault_mount" "transit" {
  path = "transit"
  type = "transit"

  depends_on = [docker_container.vault]
}

# Create the autounseal key
resource "vault_transit_secret_backend_key" "autounseal" {
  backend = vault_mount.transit.path
  name    = "autounseal"
}

# Enable KV v2 for static secrets
resource "vault_mount" "kv_v2" {
  path = "secret"
  type = "kv-v2"

  depends_on = [docker_container.vault]
}
