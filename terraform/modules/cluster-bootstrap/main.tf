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
# CoreDNS *.localhost rewrite
# ============================================================================
# Patch the existing CoreDNS ConfigMap with a wildcard regex rewrite rule
# so that any *.localhost hostname resolves to the Cilium Gateway service.
resource "kubernetes_config_map_v1_data" "coredns" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }

  force = true

  data = {
    Corefile = <<-COREFILE
      .:53 {
          errors
          health {
             lameduck 5s
          }
          ready
          rewrite name regex (.+)\.localhost cilium-gateway-main-gateway.gateway.svc.cluster.local
          kubernetes cluster.local in-addr.arpa ip6.arpa {
             pods insecure
             fallthrough in-addr.arpa ip6.arpa
             ttl 30
          }
          prometheus :9153
          forward . /etc/resolv.conf {
             max_concurrent 1000
          }
          cache 30
          loop
          reload
          loadbalance
      }
    COREFILE
  }

  depends_on = [null_resource.wait_nodes_ready]
}

# Restart CoreDNS to pick up the new Corefile immediately
resource "null_resource" "coredns_restart" {
  depends_on = [kubernetes_config_map_v1_data.coredns]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig.filename
    }
    command = "kubectl rollout restart deployment coredns -n kube-system && kubectl rollout status deployment coredns -n kube-system --timeout=60s"
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
