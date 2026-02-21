terraform {
  required_version = ">= 1.5"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.7"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
