# ============================================================================
# Cilium Cluster Mesh Connect
# Reads clustermesh-apiserver TLS certs from each cluster and creates
# cilium-clustermesh connection Secrets in the remote cluster.
# ============================================================================

provider "kubernetes" {
  alias = "kind"

  host                   = var.kind_endpoint
  cluster_ca_certificate = var.kind_cluster_ca_certificate
  client_certificate     = var.kind_client_certificate
  client_key             = var.kind_client_key
}

provider "kubernetes" {
  alias = "eks"

  host                   = var.eks_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_ca_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name, "--region", var.aws_region]
  }
}

# Read clustermesh-apiserver-remote-cert from KinD
data "kubernetes_secret" "kind_remote_cert" {
  provider = kubernetes.kind

  metadata {
    name      = "clustermesh-apiserver-remote-cert"
    namespace = "kube-system"
  }
}

# Read clustermesh-apiserver-remote-cert from EKS
data "kubernetes_secret" "eks_remote_cert" {
  provider = kubernetes.eks

  metadata {
    name      = "clustermesh-apiserver-remote-cert"
    namespace = "kube-system"
  }
}

# Read EKS node IPs for endpoint addresses
data "kubernetes_nodes" "eks" {
  provider = kubernetes.eks
}

locals {
  kind_endpoint = "${var.kind_control_plane_ip}:${var.clustermesh_apiserver_node_port}"

  eks_node_ips = [
    for node in data.kubernetes_nodes.eks.nodes :
    [for addr in node.status[0].addresses : addr.address if addr.type == "InternalIP"][0]
  ]
  eks_endpoint = "${local.eks_node_ips[0]}:${var.clustermesh_apiserver_node_port}"
}

# Create cilium-clustermesh in KinD (connection info for reaching EKS)
resource "kubernetes_secret" "kind_clustermesh" {
  provider = kubernetes.kind

  metadata {
    name      = "cilium-clustermesh"
    namespace = "kube-system"
  }

  data = {
    "eks" = yamlencode({
      endpoints       = ["https://${local.eks_endpoint}"]
      trusted-ca-file = "/var/lib/cilium/clustermesh/eks.etcd-client-ca.crt"
      key-file        = "/var/lib/cilium/clustermesh/eks.etcd-client.key"
      cert-file       = "/var/lib/cilium/clustermesh/eks.etcd-client.crt"
    })
    "eks.etcd-client-ca.crt" = data.kubernetes_secret.eks_remote_cert.data["ca.crt"]
    "eks.etcd-client.crt"    = data.kubernetes_secret.eks_remote_cert.data["tls.crt"]
    "eks.etcd-client.key"    = data.kubernetes_secret.eks_remote_cert.data["tls.key"]
  }
}

# Create cilium-clustermesh in EKS (connection info for reaching KinD)
resource "kubernetes_secret" "eks_clustermesh" {
  provider = kubernetes.eks

  metadata {
    name      = "cilium-clustermesh"
    namespace = "kube-system"
  }

  data = {
    "kind" = yamlencode({
      endpoints       = ["https://${local.kind_endpoint}"]
      trusted-ca-file = "/var/lib/cilium/clustermesh/kind.etcd-client-ca.crt"
      key-file        = "/var/lib/cilium/clustermesh/kind.etcd-client.key"
      cert-file       = "/var/lib/cilium/clustermesh/kind.etcd-client.crt"
    })
    "kind.etcd-client-ca.crt" = data.kubernetes_secret.kind_remote_cert.data["ca.crt"]
    "kind.etcd-client.crt"    = data.kubernetes_secret.kind_remote_cert.data["tls.crt"]
    "kind.etcd-client.key"    = data.kubernetes_secret.kind_remote_cert.data["tls.key"]
  }
}
