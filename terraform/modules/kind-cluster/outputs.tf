output "kubeconfig" {
  description = "Kubeconfig for the KinD cluster (raw YAML)"
  value       = kind_cluster.this.kubeconfig
  sensitive   = true
}

output "cluster_name" {
  description = "KinD cluster name"
  value       = kind_cluster.this.name
}

output "endpoint" {
  description = "Kubernetes API endpoint"
  value       = kind_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64-decoded)"
  value       = kind_cluster.this.cluster_ca_certificate
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate for K8s auth"
  value       = kind_cluster.this.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key for K8s auth"
  value       = kind_cluster.this.client_key
  sensitive   = true
}

output "vault_cluster_ip" {
  description = "Transit Vault IP on the KinD Docker network"
  value       = local.vault_cluster_ip
}

output "control_plane_ip" {
  description = "KinD control plane node IP on the Docker network"
  value       = data.external.control_plane_ip.result["ip"]
}
