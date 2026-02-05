provider "vault" {
  address = "http://${var.vm_ip}:8200"
  token   = "root"
}
