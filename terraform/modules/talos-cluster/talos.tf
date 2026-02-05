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
      cluster = {
        network = {
          cni = {
            name = "none"
          }
          podSubnets     = [var.pod_cidr]
          serviceSubnets = [var.service_cidr]
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
      cluster = {
        network = {
          cni = {
            name = "none"
          }
          podSubnets     = [var.pod_cidr]
          serviceSubnets = [var.service_cidr]
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [libvirt_domain.controlplane]

  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  endpoint                    = var.vm_controlplane_ip
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [libvirt_domain.worker]

  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  endpoint                    = var.vm_worker_ip
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker
  ]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoint             = var.vm_controlplane_ip
}

data "talos_cluster_kubeconfig" "main" {
  depends_on = [talos_machine_bootstrap.cluster]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoint             = var.vm_controlplane_ip
}
