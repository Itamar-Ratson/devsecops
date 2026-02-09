output "cluster_ca_cert" {
  description = "Kubernetes cluster CA certificate (PEM, base64-decoded)"
  value       = base64decode(talos_cluster_kubeconfig.main.kubernetes_client_configuration.ca_certificate)
  sensitive   = true
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${var.vm_controlplane_ip}:6443"
}

output "cluster_name" {
  description = "Name of the Talos cluster"
  value       = var.cluster_name
}

output "kubeconfig" {
  description = "Kubeconfig for accessing the cluster"
  value       = talos_cluster_kubeconfig.main.kubeconfig_raw
  sensitive   = true
}

output "vm_controlplane_ip" {
  description = "Static IP of the control plane VM"
  value       = var.vm_controlplane_ip
}
