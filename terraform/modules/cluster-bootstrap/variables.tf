variable "project_name" {
  description = "Project name"
  type        = string
}

variable "kubeconfig" {
  description = "Raw kubeconfig YAML from KinD cluster"
  type        = string
  sensitive   = true
}

variable "endpoint" {
  description = "Kubernetes API server endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64-decoded PEM)"
  type        = string
  sensitive   = true
}

variable "client_certificate" {
  description = "Client certificate for K8s auth"
  type        = string
  sensitive   = true
}

variable "client_key" {
  description = "Client key for K8s auth"
  type        = string
  sensitive   = true
}

variable "helm_values_dir" {
  description = "Absolute path to the helm/ directory containing chart values"
  type        = string
}

variable "gateway_api_version" {
  description = "Gateway API CRD version"
  type        = string
  default     = "v1.4.0"
}

variable "prometheus_operator_version" {
  description = "Prometheus Operator CRD version"
  type        = string
  default     = "v0.88.1"
}

variable "cert_manager_version" {
  description = "cert-manager CRD version"
  type        = string
  default     = "v1.19.3"
}

variable "argocd_version" {
  description = "ArgoCD version for CRD installation"
  type        = string
  default     = "v3.3.0"
}
