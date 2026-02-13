provider "docker" {}

resource "docker_image" "zot" {
  name = "ghcr.io/project-zot/zot-linux-amd64:${var.zot_version}"
}

resource "docker_volume" "cache" {
  name = "${var.container_name}-data"
}

resource "docker_container" "zot" {
  name    = var.container_name
  image   = docker_image.zot.image_id
  restart = "unless-stopped"

  ports {
    internal = 5000
    external = var.host_port
    ip       = "127.0.0.1"
  }

  volumes {
    volume_name    = docker_volume.cache.name
    container_path = "/var/lib/zot"
  }

  upload {
    file = "/etc/zot/config.json"
    content = jsonencode({
      distSpecVersion = "1.1.1"
      storage = {
        rootDirectory = "/var/lib/zot"
      }
      http = {
        address = "0.0.0.0"
        port    = "5000"
      }
      extensions = {
        search = {
          enable = true
        }
        ui = {
          enable = true
        }
      }
    })
  }

  command = ["serve", "/etc/zot/config.json"]
}
