resource "null_resource" "mkcert_ca" {
  provisioner "local-exec" {
    command = "mkcert -install 2>/dev/null || true"
  }

  triggers = {
    run_once = "initial_setup"
  }
}

locals {
  mkcert_ca_path = pathexpand("~/.local/share/mkcert")
}

data "local_file" "mkcert_ca_cert" {
  depends_on = [null_resource.mkcert_ca]

  filename = "${local.mkcert_ca_path}/rootCA.pem"
}

data "local_file" "mkcert_ca_key" {
  depends_on = [null_resource.mkcert_ca]

  filename = "${local.mkcert_ca_path}/rootCA-key.pem"
}

resource "kubernetes_namespace_v1" "cert_manager" {
  depends_on = [null_resource.wait_nodes]

  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_secret_v1" "mkcert_ca" {
  depends_on = [kubernetes_namespace_v1.cert_manager]

  metadata {
    name      = "mkcert-ca"
    namespace = "cert-manager"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = data.local_file.mkcert_ca_cert.content
    "tls.key" = data.local_file.mkcert_ca_key.content
  }
}

resource "kubernetes_manifest" "mkcert_issuer" {
  depends_on = [kubernetes_secret_v1.mkcert_ca]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "mkcert-ca-issuer"
    }
    spec = {
      ca = {
        secretName = "mkcert-ca"
      }
    }
  }
}
