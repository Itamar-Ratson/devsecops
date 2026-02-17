terraform {
  required_version = ">= 1.5"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.2"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.11"
    }
  }
}
