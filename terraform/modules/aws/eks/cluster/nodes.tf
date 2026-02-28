# ============================================================================
# Node IAM Role
# ============================================================================
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Project   = "devsecops"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Cilium ENI mode needs EC2 ENI management permissions
resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ============================================================================
# Managed Node Group — created AFTER Cilium so nodes become Ready
# ============================================================================
resource "aws_eks_node_group" "workers" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "spot-workers"
  node_role_arn   = aws_iam_role.node.arn

  # Workers run in first AZ only (learning/dev). Second AZ exists only to satisfy EKS control plane requirement.
  subnet_ids = [var.private_subnet_ids[0]]

  scaling_config {
    min_size     = var.node_min_size
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
  }

  instance_types = var.instance_types
  capacity_type  = var.capacity_type
  ami_type       = "AL2023_x86_64_STANDARD"

  # Cilium taint: prevent scheduling until agent is ready
  taint {
    key    = "node.cilium.io/agent-not-ready"
    effect = "NO_EXECUTE"
  }

  labels = {
    "node.kubernetes.io/purpose" = "workload"
  }

  depends_on = [
    helm_release.cilium,
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_ecr,
    aws_iam_role_policy_attachment.node_cni,
  ]

  tags = {
    Project   = "devsecops"
    ManagedBy = "terraform"
  }
}

# Wait for all nodes to be ready after node group creation
resource "null_resource" "wait_nodes_ready" {
  depends_on = [aws_eks_node_group.workers]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig.filename
    }
    command = "kubectl wait --for=condition=Ready nodes --all --timeout=300s"
  }
}

# Restart CoreDNS if it was stuck Pending before Cilium provided networking
resource "null_resource" "coredns_restart" {
  depends_on = [null_resource.wait_nodes_ready]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig.filename
    }
    command = "kubectl rollout restart deployment coredns -n kube-system && kubectl rollout status deployment coredns -n kube-system --timeout=60s"
  }
}
