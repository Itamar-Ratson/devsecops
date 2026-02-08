# Download Talos ISO
resource "libvirt_volume" "talos_iso" {
  name = "talos-${var.talos_version}.iso"
  pool = "default"

  create = {
    content = {
      url = "https://github.com/siderolabs/talos/releases/download/${var.talos_version}/metal-amd64.iso"
    }
  }
}

# Create control plane disk
resource "libvirt_volume" "controlplane_disk" {
  name     = "${var.cluster_name}-controlplane.qcow2"
  pool     = "default"
  capacity = 21474836480
}

# Create worker disk
resource "libvirt_volume" "worker_disk" {
  name     = "${var.cluster_name}-worker.qcow2"
  pool     = "default"
  capacity = 32212254720
}

# Create control plane VM
resource "libvirt_domain" "controlplane" {
  name        = "${var.cluster_name}-controlplane"
  memory      = var.controlplane_memory
  memory_unit = "MiB"
  vcpu        = var.controlplane_vcpu
  type        = "kvm"
  running     = true
  autostart   = true

  cpu = {
    mode = "host-passthrough"
  }

  sec_label = [{
    type = "none"
  }]

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    boot_devices = [
      { dev = "hd" },
      { dev = "cdrom" }
    ]
  }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = "default"
            volume = libvirt_volume.controlplane_disk.name
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
            volume = libvirt_volume.talos_iso.name
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
          address = var.vm_controlplane_mac
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

# Create worker VM
resource "libvirt_domain" "worker" {
  name        = "${var.cluster_name}-worker"
  memory      = var.worker_memory
  memory_unit = "MiB"
  vcpu        = var.worker_vcpu
  type        = "kvm"
  running     = true
  autostart   = true

  cpu = {
    mode = "host-passthrough"
  }

  sec_label = [{
    type = "none"
  }]

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    boot_devices = [
      { dev = "hd" },
      { dev = "cdrom" }
    ]
  }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = "default"
            volume = libvirt_volume.worker_disk.name
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
            volume = libvirt_volume.talos_iso.name
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
          address = var.vm_worker_mac
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
