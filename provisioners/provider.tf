// provider 
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.28.0"
    }
  }
}

// configure the provider
provider "azurerm" {
  subscription_id = ""
  tenant_id       = ""
  client_id       = "" # appID
  client_secret   = "" # password
  features {}
}