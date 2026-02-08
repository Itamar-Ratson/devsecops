# Download Ubuntu cloud image directly (no backing store due to provider limitations)
# Base image (golden image, read-only)
resource "libvirt_volume" "base_image" {
  name = "${var.vm_name}-base.qcow2"
  pool = "default"

  create = {
    content = {
      url = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
    }
  }
}

# VM disk (copy-on-write overlay with larger capacity)
resource "libvirt_volume" "vault_disk" {
  name     = "${var.vm_name}.qcow2"
  pool     = "default"
  capacity = var.vm_disk_size

  target = {
    format = { type = "qcow2" }
  }

  backing_store = {
    path   = libvirt_volume.base_image.path
    format = { type = "qcow2" }
  }
}

# Generate cloud-init ISO
resource "libvirt_cloudinit_disk" "vault_init" {
  name = "${var.vm_name}-init"
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    vault_version  = var.vault_version
    vm_ip          = var.vm_ip
    ssh_public_key = var.ssh_public_key
  })
  meta_data = yamlencode({
    instance-id    = var.vm_name
    local-hostname = var.vm_name
  })
  network_config = yamlencode({
    version = 2
    ethernets = {
      eth0 = {
        match     = { name = "en*" }
        addresses = ["${var.vm_ip}/24"]
        routes    = [{ to = "default", via = "192.168.100.1" }]
        nameservers = {
          addresses = ["8.8.8.8", "8.8.4.4"]
        }
      }
    }
  })
}

# Upload cloud-init ISO to libvirt volume
resource "libvirt_volume" "cloudinit" {
  name = "${var.vm_name}-cloudinit.iso"
  pool = "default"

  create = {
    content = {
      url = libvirt_cloudinit_disk.vault_init.path
    }
  }
}

# Create Vault VM
resource "libvirt_domain" "vault" {
  name        = var.vm_name
  memory      = var.vm_memory
  memory_unit = "MiB"
  vcpu        = var.vm_vcpu
  type        = "kvm"
  running     = true
  autostart   = true

  sec_label = [{
    type = "none"
  }]

  os = {
    type      = "hvm"
    type_arch = "x86_64"
    boot_devices = [
      { dev = "hd" }
    ]
  }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = "default"
            volume = libvirt_volume.vault_disk.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      },
      {
        source = {
          volume = {
            pool   = "default"
            volume = libvirt_volume.cloudinit.name
          }
        }
        target = {
          dev = "hda"
          bus = "ide"
        }
        driver = {
          type = "raw"
        }
        device = "cdrom"
      }
    ]

    interfaces = [
      {
        mac = {
          address = var.vm_mac
        }
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = var.network_name
          }
        }
      }
    ]

    consoles = [
      {
        target = {
          type = "serial"
          port = "0"
        }
      }
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Wait for Vault to be ready
resource "null_resource" "wait_for_vault" {
  depends_on = [libvirt_domain.vault]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Waiting for Vault to be ready at ${var.vm_ip}:8200..."
      for i in {1..60}; do
        if curl -s -o /dev/null -w "%%{http_code}" http://${var.vm_ip}:8200/v1/sys/health | grep -q "200\|429\|501\|503"; then
          echo "Vault is ready!"
          # Disable default secret/ engine (dev mode creates it, terraform will manage it)
          curl -sf -X DELETE -H "X-Vault-Token: root" http://${var.vm_ip}:8200/v1/sys/mounts/secret || true
          exit 0
        fi
        echo "Attempt $i/60: Vault not ready yet, waiting..."
        sleep 5
      done
      echo "Timeout waiting for Vault to be ready"
      exit 1
    EOT
  }
}
