provider "kubernetes" {
  host                   = var.endpoint
  cluster_ca_certificate = var.cluster_ca_certificate
  client_certificate     = var.client_certificate
  client_key             = var.client_key
}

provider "helm" {
  kubernetes = {
    host                   = var.endpoint
    cluster_ca_certificate = var.cluster_ca_certificate
    client_certificate     = var.client_certificate
    client_key             = var.client_key
  }
}

# Write kubeconfig to disk for kubectl commands in null_resource provisioners
resource "local_sensitive_file" "kubeconfig" {
  content  = var.kubeconfig
  filename = "${path.module}/.kubeconfig"
}

# ============================================================================
# Cilium CNI
# ============================================================================
resource "helm_release" "cilium" {
  name          = "cilium"
  namespace     = "kube-system"
  chart         = "${var.helm_values_dir}/cilium"
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  values = [file("${var.helm_values_dir}/ports.yaml")]

  depends_on = [null_resource.gateway_api_crds, null_resource.prometheus_operator_crds, null_resource.cert_manager_crds]
}

# Wait for all nodes to be ready after Cilium installation
resource "null_resource" "wait_nodes_ready" {
  depends_on = [helm_release.cilium]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig.filename
    }
    command = "kubectl wait --for=condition=Ready nodes --all --timeout=300s"
  }
}

# ============================================================================
# Sealed-Secrets
# ============================================================================
resource "helm_release" "sealed_secrets" {
  name             = "sealed-secrets"
  namespace        = "sealed-secrets"
  create_namespace = true
  chart            = "${var.helm_values_dir}/sealed-secrets"
  wait             = true
  timeout          = 120

  values = [file("${var.helm_values_dir}/ports.yaml")]

  depends_on = [null_resource.wait_nodes_ready]
}
