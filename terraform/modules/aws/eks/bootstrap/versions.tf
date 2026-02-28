terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.6"
    }
  }
}
