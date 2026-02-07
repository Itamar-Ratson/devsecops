terraform {
  required_version = ">= 1.10.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.6"
    }
  }
}
