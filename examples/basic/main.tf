terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
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

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "cosmosdb_endpoint" {
  value = module.cosmosdb.endpoint
}
