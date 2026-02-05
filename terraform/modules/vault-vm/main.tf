# Download Ubuntu cloud image
resource "libvirt_volume" "vault_base" {
  name = "${var.vm_name}-base.qcow2"
  pool = "default"

  create = {
    content = {
      url = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
    }
  }
}

# Create COW volume from base image
resource "libvirt_volume" "vault_disk" {
  name     = "${var.vm_name}.qcow2"
  pool     = "default"
  capacity = 10737418240

  backing_store = {
    path = libvirt_volume.vault_base.path
  }
}

# Generate cloud-init ISO
resource "libvirt_cloudinit_disk" "vault_init" {
  name = "${var.vm_name}-init"
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    vault_version = var.vault_version
    vm_ip         = var.vm_ip
  })
  meta_data = yamlencode({
    instance-id    = var.vm_name
    local-hostname = var.vm_name
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
  name      = var.vm_name
  memory    = var.vm_memory
  vcpu      = var.vm_vcpu
  type      = "kvm"
  autostart = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
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
      },
      {
        source = {
          volume = {
            pool   = "default"
            volume = libvirt_volume.cloudinit.name
          }
        }
        target = {
          dev = "vdb"
          bus = "virtio"
        }
      }
    ]

    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = var.network_name
          }
        }
        addresses = [var.vm_ip]
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

    graphics = [
      {
        type = "spice"
        listen = {
          type = "address"
        }
        autoport = true
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
    command = <<-EOT
      echo "Waiting for Vault to be ready at ${var.vm_ip}:8200..."
      for i in {1..60}; do
        if curl -s -o /dev/null -w "%%{http_code}" http://${var.vm_ip}:8200/v1/sys/health | grep -q "200\|429\|501\|503"; then
          echo "Vault is ready!"
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
