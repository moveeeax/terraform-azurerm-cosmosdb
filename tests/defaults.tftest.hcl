# Runs with a mocked azurerm provider, so it needs no Azure credentials and no
# network. `mock_provider` requires Terraform >= 1.7 (or OpenTofu >= 1.7) to run
# the tests; the module itself still supports >= 1.5, which is why
# required_version is not bumped.

mock_provider "azurerm" {}

variables {
  name                = "example-cosmos01"
  resource_group_name = "example-rg"
  location            = "eastus"
}

run "defaults_are_safe" {
  assert {
    condition     = azurerm_cosmosdb_account.this.public_network_access_enabled == false
    error_message = "The account must not be reachable from the public internet by default."
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.minimal_tls_version == "Tls12"
    error_message = "The account must reject anything below TLS 1.2 by default."
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.backup[0].type == "Periodic"
    error_message = "Backup must be configured explicitly rather than left to the provider."
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.backup[0].storage_redundancy == "Geo"
    error_message = "Periodic backups must be geo-redundant by default."
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.consistency_policy[0].consistency_level == "Session"
    error_message = "Default consistency level should be Session."
  }
}

run "staleness_is_omitted_for_non_bounded_levels" {
  variables {
    consistency_level = "Strong"
  }

  # Sending these on any level other than BoundedStaleness is an apply-time
  # error from the Cosmos DB API, so the module must drop them.
  assert {
    condition     = azurerm_cosmosdb_account.this.consistency_policy[0].max_staleness_prefix == null
    error_message = "max_staleness_prefix must not be sent when consistency_level is not BoundedStaleness."
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.consistency_policy[0].max_interval_in_seconds == null
    error_message = "max_interval_in_seconds must not be sent when consistency_level is not BoundedStaleness."
  }
}

run "staleness_is_sent_for_bounded_staleness" {
  variables {
    consistency_level       = "BoundedStaleness"
    max_staleness_prefix    = 200000
    max_interval_in_seconds = 600
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.consistency_policy[0].max_staleness_prefix == 200000
    error_message = "max_staleness_prefix must be sent when consistency_level is BoundedStaleness."
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.consistency_policy[0].max_interval_in_seconds == 600
    error_message = "max_interval_in_seconds must be sent when consistency_level is BoundedStaleness."
  }
}

run "primary_region_is_always_geo_location_zero" {
  variables {
    additional_geo_locations = [
      { location = "westus", failover_priority = 1 },
    ]
  }

  assert {
    condition     = one([for g in azurerm_cosmosdb_account.this.geo_location : g.location if g.failover_priority == 0]) == "eastus"
    error_message = "The primary region must be the failover_priority 0 geo_location."
  }

  assert {
    condition     = length(azurerm_cosmosdb_account.this.geo_location) == 2
    error_message = "Additional geo locations must be appended to the primary one."
  }
}
