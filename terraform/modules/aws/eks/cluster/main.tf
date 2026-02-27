module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Prevent aws-vpc-cni from being installed (Cilium replaces it)
  bootstrap_self_managed_addons = false

  # Only install CoreDNS as a managed addon.
  # kube-proxy is NOT installed — Cilium replaces it via eBPF (kubeProxyReplacement: true).
  # vpc-cni is NOT installed — Cilium ENI mode provides pod networking.
  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        # CoreDNS starts in Pending until Cilium provides networking
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

  # Managed node group
  eks_managed_node_groups = {
    spot-workers = {
      instance_types = var.instance_types
      capacity_type  = var.capacity_type
      ami_type       = "AL2023_x86_64_STANDARD"

      min_size     = var.node_min_size
      desired_size = var.node_desired_size
      max_size     = var.node_max_size

      # Cilium taint: prevent scheduling until agent is ready
      taints = {
        cilium = {
          key    = "node.cilium.io/agent-not-ready"
          value  = ""
          effect = "NO_EXECUTE"
        }
      }

      labels = {
        "node.kubernetes.io/purpose" = "workload"
      }
    }
  }

  # Allow all traffic between nodes (Cilium ENI mode needs pod-to-pod via VPC fabric)
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all traffic (Cilium ENI mode)"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  tags = {
    Project   = "devsecops"
    ManagedBy = "terraform"
  }
}
