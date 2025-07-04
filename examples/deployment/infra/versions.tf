terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.35.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }

    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
    }
  }
}
