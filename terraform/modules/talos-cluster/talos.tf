resource "talos_machine_secrets" "cluster" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  cluster_endpoint = "https://${var.vm_controlplane_ip}:6443"

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/vda"
        }
      }
      cluster = {
        network = {
          cni = {
            name = "none"
          }
          podSubnets     = [var.pod_cidr]
          serviceSubnets = [var.service_cidr]
        }
        proxy = {
          disabled = true
        }
      }
    })
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  cluster_endpoint = "https://${var.vm_controlplane_ip}:6443"

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/vda"
        }
      }
      cluster = {
        network = {
          cni = {
            name = "none"
          }
          podSubnets     = [var.pod_cidr]
          serviceSubnets = [var.service_cidr]
        }
        proxy = {
          disabled = true
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [libvirt_domain.controlplane]

  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = var.vm_controlplane_ip
  endpoint                    = var.vm_controlplane_ip
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [libvirt_domain.worker]

  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = var.vm_worker_ip
  endpoint                    = var.vm_worker_ip
}

# Wait for Talos to install to disk and reboot into running mode
resource "null_resource" "wait_for_talos_install" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Phase 1: Waiting for Talos to install and start rebooting..."
      echo "Giving install 30s head start..."
      sleep 30
      echo "Waiting for port 50000 to go DOWN (reboot started)..."
      for i in {1..180}; do
        if ! nc -z -w2 ${var.vm_controlplane_ip} 50000 2>/dev/null; then
          echo "Port 50000 is down - node is rebooting!"
          break
        fi
        echo "Attempt $i/180: Node still installing (port 50000 still up)..."
        sleep 5
      done
      echo ""
      echo "Phase 2: Waiting for node to come back up in running mode..."
      sleep 10
      for i in {1..120}; do
        if nc -z -w2 ${var.vm_controlplane_ip} 50000 2>/dev/null; then
          echo "Talos controlplane API is back up in running mode!"
          echo "Waiting 15s for API to fully initialize..."
          sleep 15
          exit 0
        fi
        echo "Attempt $i/120: Talos API not ready yet..."
        sleep 5
      done
      echo "Timeout waiting for Talos API"
      exit 1
    EOT
  }
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on = [null_resource.wait_for_talos_install]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  node                 = var.vm_controlplane_ip
  endpoint             = var.vm_controlplane_ip
}

resource "talos_cluster_kubeconfig" "main" {
  depends_on = [talos_machine_bootstrap.cluster]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  node                 = var.vm_controlplane_ip
}
