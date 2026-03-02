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

# Resolve NLB DNS to IP via VPC DNS (10.50.0.2, reachable over Tailscale)
data "external" "eks_nlb_ip" {
  program = [
    "bash", "-c",
    "ip=$(dig +short '${var.eks_clustermesh_nlb_dns}' @10.50.0.2 | head -1) && echo \"{\\\"ip\\\": \\\"$ip\\\"}\"",
  ]
}

locals {
  kind_endpoint = "${var.kind_control_plane_ip}:${var.clustermesh_apiserver_node_port}"
  eks_endpoint  = "${data.external.eks_nlb_ip.result.ip}:2379"
}

# Connection data reused by both cilium-clustermesh and cilium-kvstoremesh secrets.
# cilium-clustermesh is mounted by Cilium agents; cilium-kvstoremesh by KVStoreMesh.
# NOTE: Cilium's isEtcdConfigFile() does a raw string search for "endpoints:" —
# yamlencode() quotes keys ("endpoints":) which Cilium doesn't recognize.
# Use heredoc templates instead.
locals {
  kind_clustermesh_data = {
    "eks" = <<-YAML
      endpoints:
      - https://${local.eks_endpoint}
      trusted-ca-file: /var/lib/cilium/clustermesh/eks.etcd-client-ca.crt
      key-file: /var/lib/cilium/clustermesh/eks.etcd-client.key
      cert-file: /var/lib/cilium/clustermesh/eks.etcd-client.crt
    YAML
    "eks.etcd-client-ca.crt" = data.kubernetes_secret.eks_remote_cert.data["ca.crt"]
    "eks.etcd-client.crt"    = data.kubernetes_secret.eks_remote_cert.data["tls.crt"]
    "eks.etcd-client.key"    = data.kubernetes_secret.eks_remote_cert.data["tls.key"]
  }

  eks_clustermesh_data = {
    "kind" = <<-YAML
      endpoints:
      - https://${local.kind_endpoint}
      trusted-ca-file: /var/lib/cilium/clustermesh/kind.etcd-client-ca.crt
      key-file: /var/lib/cilium/clustermesh/kind.etcd-client.key
      cert-file: /var/lib/cilium/clustermesh/kind.etcd-client.crt
    YAML
    "kind.etcd-client-ca.crt" = data.kubernetes_secret.kind_remote_cert.data["ca.crt"]
    "kind.etcd-client.crt"    = data.kubernetes_secret.kind_remote_cert.data["tls.crt"]
    "kind.etcd-client.key"    = data.kubernetes_secret.kind_remote_cert.data["tls.key"]
  }
}

# Create cilium-clustermesh in KinD (mounted by Cilium agents)
resource "kubernetes_secret" "kind_clustermesh" {
  provider = kubernetes.kind

  metadata {
    name      = "cilium-clustermesh"
    namespace = "kube-system"
  }

  data = local.kind_clustermesh_data
}

# Create cilium-kvstoremesh in KinD (mounted by KVStoreMesh sidecar)
resource "kubernetes_secret" "kind_kvstoremesh" {
  provider = kubernetes.kind

  metadata {
    name      = "cilium-kvstoremesh"
    namespace = "kube-system"
  }

  data = local.kind_clustermesh_data
}

# Create cilium-clustermesh in EKS (mounted by Cilium agents)
resource "kubernetes_secret" "eks_clustermesh" {
  provider = kubernetes.eks

  metadata {
    name      = "cilium-clustermesh"
    namespace = "kube-system"
  }

  data = local.eks_clustermesh_data
}

# Create cilium-kvstoremesh in EKS (mounted by KVStoreMesh sidecar)
resource "kubernetes_secret" "eks_kvstoremesh" {
  provider = kubernetes.eks

  metadata {
    name      = "cilium-kvstoremesh"
    namespace = "kube-system"
  }

  data = local.eks_clustermesh_data
}
