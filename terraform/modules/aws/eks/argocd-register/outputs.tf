output "eks_cluster_registered" {
  description = "Whether the EKS cluster was registered with ArgoCD"
  value       = true

  depends_on = [kubernetes_secret_v1.eks_cluster]
}
