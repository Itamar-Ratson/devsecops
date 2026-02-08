provider "helm" {
  kubernetes = {
    host                   = talos_cluster_kubeconfig.main.kubernetes_client_configuration.host
    client_certificate     = base64decode(talos_cluster_kubeconfig.main.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.main.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.main.kubernetes_client_configuration.ca_certificate)
  }
}

provider "kubernetes" {
  host                   = talos_cluster_kubeconfig.main.kubernetes_client_configuration.host
  client_certificate     = base64decode(talos_cluster_kubeconfig.main.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.main.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.main.kubernetes_client_configuration.ca_certificate)
}

resource "null_resource" "wait_for_k8s_api" {
  depends_on = [talos_machine_bootstrap.cluster]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Waiting for Kubernetes API to be ready..."
      for i in {1..120}; do
        if curl -sk https://${var.vm_controlplane_ip}:6443/version >/dev/null 2>&1; then
          echo "Kubernetes API is ready!"
          exit 0
        fi
        echo "Attempt $i/120: K8s API not ready yet..."
        sleep 5
      done
      echo "Timeout waiting for Kubernetes API"
      exit 1
    EOT
  }
}

resource "helm_release" "cilium" {
  depends_on = [null_resource.wait_for_k8s_api]

  name  = "cilium"
  chart = "${var.helm_values_dir}/cilium"
  namespace  = "kube-system"

  values = [
    file("${var.helm_values_dir}/ports.yaml"),
    file("${var.helm_values_dir}/cilium/values.yaml"),
    yamlencode({
      cilium = {
        # Talos-specific: use existing cgroup/bpf mounts
        cgroup = {
          autoMount = { enabled = false }
          hostRoot  = "/sys/fs/cgroup"
        }
        # Talos-specific: capabilities without SYS_MODULE (Talos blocks kernel module loading)
        securityContext = {
          capabilities = {
            ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
            cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
          }
        }
        # Talos kube-proxy replacement settings
        k8sServiceHost = "localhost"
        k8sServicePort = 7445
        bgpControlPlane = {
          enabled = true
        }
        bgp = {
          enabled = true
          announce = {
            loadbalancerIP = true
          }
        }
        # Disable ServiceMonitors for initial install (Prometheus CRDs not yet available)
        # ArgoCD will re-deploy Cilium with ServiceMonitors enabled later
        prometheus = {
          serviceMonitor = {
            enabled = false
          }
        }
        operator = {
          prometheus = {
            serviceMonitor = {
              enabled = false
            }
          }
        }
        hubble = {
          relay = {
            prometheus = {
              serviceMonitor = {
                enabled = false
              }
            }
          }
          metrics = {
            serviceMonitor = {
              enabled = false
            }
          }
        }
      }
    })
  ]
}

resource "local_sensitive_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.main.kubeconfig_raw
  filename = pathexpand("~/.kube/config")
}

resource "null_resource" "wait_nodes" {
  depends_on = [helm_release.cilium, local_sensitive_file.kubeconfig]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Waiting for nodes to register and become Ready..."
      for i in {1..60}; do
        NODE_COUNT=$(kubectl --kubeconfig=${local_sensitive_file.kubeconfig.filename} get nodes --no-headers 2>/dev/null | wc -l)
        if [ "$NODE_COUNT" -gt 0 ]; then
          echo "Found $NODE_COUNT node(s), waiting for Ready condition..."
          kubectl --kubeconfig=${local_sensitive_file.kubeconfig.filename} wait --for=condition=Ready nodes --all --timeout=300s && exit 0
        fi
        echo "Attempt $i/60: No nodes registered yet..."
        sleep 5
      done
      echo "Timeout waiting for nodes"
      exit 1
    EOT
  }
}
