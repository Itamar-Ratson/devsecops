variable "kind_control_plane_ip" {
  description = "KinD control plane node IP on Docker network (for clustermesh-apiserver endpoint)"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name (for aws eks get-token)"
  type        = string
}

variable "clustermesh_apiserver_node_port" {
  description = "NodePort for clustermesh-apiserver service"
  type        = number
  default     = 32379
}

variable "kind_endpoint" {
  description = "KinD cluster API endpoint"
  type        = string
}

variable "kind_cluster_ca_certificate" {
  description = "KinD cluster CA certificate (PEM, base64-decoded)"
  type        = string
  sensitive   = true
}

variable "kind_client_certificate" {
  description = "KinD client certificate (PEM)"
  type        = string
  sensitive   = true
}

variable "kind_client_key" {
  description = "KinD client key (PEM)"
  type        = string
  sensitive   = true
}

variable "eks_endpoint" {
  description = "EKS cluster API endpoint"
  type        = string
}

variable "eks_cluster_ca_data" {
  description = "EKS cluster CA certificate (base64-encoded)"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for EKS authentication"
  type        = string
  default     = "eu-north-1"
}
