terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.2"
    }
  }
}

locals {
  operator_version = "1.2.8"
  helm_version     = "0.6.83"
  crd_version      = "0.1.1"
}
