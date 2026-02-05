terraform {
  required_version = ">= 1.6.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

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

    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.10"
    }
  }
}
