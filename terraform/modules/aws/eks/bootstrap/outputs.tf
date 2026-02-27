output "argocd_manager_token" {
  description = "Long-lived SA token for ArgoCD to manage the EKS cluster"
  value       = kubernetes_secret_v1.argocd_manager_token.data["token"]
  sensitive   = true
}

output "eso_irsa_role_arn" {
  description = "IAM role ARN for ESO IRSA"
  value       = aws_iam_role.eso.arn
}
