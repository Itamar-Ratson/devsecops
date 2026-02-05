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

resource "helm_release" "cilium" {
  depends_on = [talos_machine_bootstrap.cluster]

  name       = "cilium"
  repository = "file://../../../helm/cilium"
  chart      = "cilium"
  namespace  = "kube-system"

  values = [
    file("${path.root}/../../../helm/ports.yaml"),
    file("${path.root}/../../../helm/cilium/values.yaml"),
    yamlencode({
      cilium = {
        bgpControlPlane = {
          enabled = true
        }
        bgp = {
          enabled = true
          announce = {
            loadbalancerIP = true
          }
        }
      }
    })
  ]
}

resource "null_resource" "wait_nodes" {
  depends_on = [helm_release.cilium]

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=<(echo '${talos_cluster_kubeconfig.main.kubeconfig_raw}') wait --for=condition=Ready nodes --all --timeout=300s"
  }
}
