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
