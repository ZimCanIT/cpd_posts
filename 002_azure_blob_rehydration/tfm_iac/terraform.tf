terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.11.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
  }
}