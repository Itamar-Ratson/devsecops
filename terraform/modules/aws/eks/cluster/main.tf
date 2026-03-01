data "aws_region" "current" {}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", data.aws_region.current.name]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", data.aws_region.current.name]
    }
  }
}

# ============================================================================
# EKS Control Plane (no node groups — created separately after Cilium)
# ============================================================================
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Prevent aws-vpc-cni from being installed (Cilium replaces it)
  bootstrap_self_managed_addons = false

  # kube-proxy is NOT installed — Cilium replaces it via eBPF (kubeProxyReplacement: true).
  # vpc-cni is NOT installed — Cilium ENI mode provides pod networking.
  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        tolerations = [{
          key      = "node.cilium.io/agent-not-ready"
          operator = "Exists"
          effect   = "NoExecute"
        }]
      })
    }
  }

  # Access configuration
  # Public access restricted to operator IPs; private access for in-cluster components.
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = var.allowed_public_cidrs

  # Allow Terraform/ArgoCD access
  enable_cluster_creator_admin_permissions = true

  tags = {
    Project   = "devsecops"
    ManagedBy = "terraform"
  }
}

# ============================================================================
# Cluster Mesh + Tailscale ingress rules on node security group
# ============================================================================

# WireGuard — Cilium node-to-node encryption (Tailscale peers have arbitrary public IPs)
resource "aws_vpc_security_group_ingress_rule" "wireguard" {
  security_group_id = module.eks.node_security_group_id
  description       = "WireGuard (Cilium encryption)"
  ip_protocol       = "udp"
  from_port         = 51871
  to_port           = 51871
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "${var.cluster_name}-wireguard" }
}

# Clustermesh-apiserver NodePort — remote Cilium agents connect via Tailscale (CGNAT range)
resource "aws_vpc_security_group_ingress_rule" "clustermesh_apiserver" {
  security_group_id = module.eks.node_security_group_id
  description       = "Clustermesh apiserver NodePort (Tailscale CGNAT)"
  ip_protocol       = "tcp"
  from_port         = 32379
  to_port           = 32379
  cidr_ipv4         = "100.64.0.0/10"

  tags = { Name = "${var.cluster_name}-clustermesh-apiserver" }
}

# Cilium health checks — cross-cluster health probes via Tailscale
resource "aws_vpc_security_group_ingress_rule" "cilium_health" {
  security_group_id = module.eks.node_security_group_id
  description       = "Cilium health checks (Tailscale CGNAT)"
  ip_protocol       = "tcp"
  from_port         = 4240
  to_port           = 4240
  cidr_ipv4         = "100.64.0.0/10"

  tags = { Name = "${var.cluster_name}-cilium-health" }
}

# Write kubeconfig to disk for kubectl commands in null_resource provisioners
resource "local_sensitive_file" "kubeconfig" {
  content = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      cluster = {
        server                     = module.eks.cluster_endpoint
        certificate-authority-data = module.eks.cluster_certificate_authority_data
      }
      name = var.cluster_name
    }]
    contexts = [{
      context = {
        cluster = var.cluster_name
        user    = var.cluster_name
      }
      name = var.cluster_name
    }]
    current-context = var.cluster_name
    users = [{
      name = var.cluster_name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args       = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", data.aws_region.current.name]
        }
      }
    }]
  })
  filename = "/tmp/devsecops-eks-kubeconfig"
}

# Add EKS cluster to user's kubeconfig
resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${data.aws_region.current.name} --alias eks"
  }
}
