terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # 3.99.0 is the first release that accepts the current argument names on
      # azurerm_cosmosdb_account: automatic_failover_enabled and
      # multiple_write_locations_enabled were back-ported from the 4.0 rename in
      # that release. Anything older fails with "Unsupported argument".
      #
      # 5.0 removed local_authentication_disabled (replaced by
      # local_authentication_enabled, which only exists from 4.78.0), so no
      # single argument name covers 3.99 through 5.x. This line stays on < 5.0.
      version = ">= 3.99.0, < 5.0"
    }
  }
}
