terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.99.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "cosmosdb" {
  source = "../.."

  name                = "example-cosmos01"
  resource_group_name = "example-rg"
  location            = "eastus"

  consistency_level = "Session"

  # public_network_access_enabled defaults to false, so this account is only
  # reachable through a private endpoint. Set it to true if you need to reach it
  # over the internet.

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "cosmosdb_endpoint" {
  value = module.cosmosdb.endpoint
}
