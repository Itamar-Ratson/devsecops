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
  value       = data.talos_cluster_kubeconfig.main.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Talosconfig for managing the cluster"
  value       = data.talos_cluster_kubeconfig.main.talos_config
  sensitive   = true
}
