locals {
  kubeconfig = yamldecode(var.kubeconfig)
}

provider "helm" {
  kubernetes = {
    host                   = local.kubeconfig.clusters[0].cluster.server
    cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
    client_certificate     = base64decode(local.kubeconfig.users[0].user["client-certificate-data"])
    client_key             = base64decode(local.kubeconfig.users[0].user["client-key-data"])
  }
}

provider "kubernetes" {
  host                   = local.kubeconfig.clusters[0].cluster.server
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
  client_certificate     = base64decode(local.kubeconfig.users[0].user["client-certificate-data"])
  client_key             = base64decode(local.kubeconfig.users[0].user["client-key-data"])
}

resource "null_resource" "wait_for_k8s_api" {
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

resource "local_sensitive_file" "kubeconfig" {
  content  = var.kubeconfig
  filename = pathexpand("~/.kube/config")
}
