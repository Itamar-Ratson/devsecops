# ============================================================================
# Internal NLB for Clustermesh-Apiserver
# Provides stable endpoint for cross-cluster Cilium Cluster Mesh connectivity.
# Spot instance replacements are handled transparently via ASG attachment.
# ============================================================================

resource "aws_lb" "clustermesh" {
  name               = "${var.cluster_name}-clustermesh"
  internal           = true
  load_balancer_type = "network"
  subnets            = [var.private_subnet_ids[0]]

  tags = {
    Project   = "devsecops"
    ManagedBy = "terraform"
  }
}

resource "aws_lb_target_group" "clustermesh" {
  name     = "${var.cluster_name}-clustermesh"
  port     = 32379
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "TCP"
    port                = "32379"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }

  tags = {
    Project   = "devsecops"
    ManagedBy = "terraform"
  }
}

resource "aws_lb_listener" "clustermesh" {
  load_balancer_arn = aws_lb.clustermesh.arn
  port              = 2379
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clustermesh.arn
  }
}

resource "aws_autoscaling_attachment" "clustermesh" {
  autoscaling_group_name = aws_eks_node_group.workers.resources[0].autoscaling_groups[0].name
  lb_target_group_arn    = aws_lb_target_group.clustermesh.arn
}
