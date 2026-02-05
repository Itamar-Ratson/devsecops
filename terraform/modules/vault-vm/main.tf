resource "libvirt_volume" "vault_base" {
  name   = "${var.vm_name}-base.qcow2"
  source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  format = "qcow2"
  pool   = "default"
}

resource "libvirt_volume" "vault_disk" {
  name           = "${var.vm_name}.qcow2"
  base_volume_id = libvirt_volume.vault_base.id
  size           = 10737418240
  pool           = "default"
}

resource "libvirt_cloudinit_disk" "vault_init" {
  name = "${var.vm_name}-init.iso"
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    vault_version = var.vault_version
    vm_ip         = var.vm_ip
  })
  pool = "default"
}

resource "libvirt_domain" "vault" {
  name      = var.vm_name
  memory    = var.vm_memory
  vcpu      = var.vm_vcpu
  autostart = true

  cloudinit = libvirt_cloudinit_disk.vault_init.id

  disk {
    volume_id = libvirt_volume.vault_disk.id
  }

  network_interface {
    network_id     = var.network_id
    wait_for_lease = true
    addresses      = [var.vm_ip]
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

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
