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
  subscription_id = "subscription id "
  tenant_id       = "tenant id "
  client_id       = "alient id " # appID
  client_secret   = "client secret" # password
  features {}
}