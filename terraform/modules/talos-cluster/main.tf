resource "libvirt_volume" "talos_iso" {
  name   = "talos-${var.talos_version}.iso"
  source = "https://github.com/siderolabs/talos/releases/download/${var.talos_version}/metal-amd64.iso"
  format = "raw"
  pool   = "default"
}

resource "libvirt_volume" "controlplane_disk" {
  name   = "${var.cluster_name}-controlplane.qcow2"
  size   = 21474836480
  format = "qcow2"
  pool   = "default"
}

resource "libvirt_volume" "worker_disk" {
  name   = "${var.cluster_name}-worker.qcow2"
  size   = 32212254720
  format = "qcow2"
  pool   = "default"
}

resource "libvirt_domain" "controlplane" {
  name      = "${var.cluster_name}-controlplane"
  memory    = var.controlplane_memory
  vcpu      = var.controlplane_vcpu
  autostart = true

  disk {
    volume_id = libvirt_volume.controlplane_disk.id
  }

  disk {
    file = libvirt_volume.talos_iso.id
  }

  network_interface {
    network_id     = var.network_id
    wait_for_lease = true
    addresses      = [var.vm_controlplane_ip]
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

resource "libvirt_domain" "worker" {
  name      = "${var.cluster_name}-worker"
  memory    = var.worker_memory
  vcpu      = var.worker_vcpu
  autostart = true

  disk {
    volume_id = libvirt_volume.worker_disk.id
  }

  disk {
    file = libvirt_volume.talos_iso.id
  }

  network_interface {
    network_id     = var.network_id
    wait_for_lease = true
    addresses      = [var.vm_worker_ip]
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
