terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.11.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
  }
}