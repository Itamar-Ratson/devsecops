variable "kubeconfig" {
  description = "Raw kubeconfig YAML content for the cluster"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
}

variable "vm_controlplane_ip" {
  description = "Static IP for control plane VM (used for K8s API readiness check)"
  type        = string
}

variable "helm_values_dir" {
  description = "Absolute path to the helm/ directory containing chart values"
  type        = string
}
