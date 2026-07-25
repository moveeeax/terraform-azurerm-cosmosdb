terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # 3.99.0 is the first release that accepts the current argument names on
      # azurerm_cosmosdb_account: automatic_failover_enabled and
      # multiple_write_locations_enabled were back-ported from the 4.0 rename in
      # that release. Anything older fails with "Unsupported argument".
      version = ">= 3.99.0"
    }
  }
}
