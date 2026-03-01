feature "deploy_eks" {
  default = true
}

exclude {
  if      = !feature.deploy_eks.value
  actions = ["apply", "plan", "destroy"]
}

terraform {
  source = "../../../modules/k8s/cluster-mesh-connect"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependencies {
  paths = ["./workspace", "../bootstrap/cluster"]
}

dependency "kind_cluster" {
  config_path = "../kind"

  mock_outputs = {
    endpoint               = "https://127.0.0.1:6443"
    cluster_ca_certificate = "mock-ca"
    client_certificate     = "mock-cert"
    client_key             = "mock-key"
    control_plane_ip       = "172.18.0.2"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "eks_cluster" {
  config_path = "../../aws/eks/cluster"

  mock_outputs = {
    cluster_endpoint                   = "https://mock.eks.amazonaws.com"
    cluster_certificate_authority_data = "bW9jaw=="
    cluster_name                       = "devsecops-eks"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  kind_endpoint               = dependency.kind_cluster.outputs.endpoint
  kind_cluster_ca_certificate = dependency.kind_cluster.outputs.cluster_ca_certificate
  kind_client_certificate     = dependency.kind_cluster.outputs.client_certificate
  kind_client_key             = dependency.kind_cluster.outputs.client_key
  kind_control_plane_ip       = dependency.kind_cluster.outputs.control_plane_ip

  eks_endpoint        = dependency.eks_cluster.outputs.cluster_endpoint
  eks_cluster_ca_data = dependency.eks_cluster.outputs.cluster_certificate_authority_data
  eks_cluster_name    = dependency.eks_cluster.outputs.cluster_name
  aws_region          = "eu-north-1"
}
