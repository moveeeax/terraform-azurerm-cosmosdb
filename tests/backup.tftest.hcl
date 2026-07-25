# interval_in_minutes, retention_in_hours and storage_redundancy are rejected by
# the Cosmos DB API on a Continuous-backup account, and tier is rejected on a
# Periodic one, so the module drops whichever set does not apply.
#
# Run order matters: the Continuous case must come first, while state is still
# empty. These attributes are Optional (and some Computed), so a run that leaves
# one unset inherits whatever an earlier run in this file put in state.
#
# `mock_provider` requires Terraform >= 1.7 (or OpenTofu >= 1.7) to run.

mock_provider "azurerm" {}

variables {
  name                = "example-cosmos01"
  resource_group_name = "example-rg"
  location            = "eastus"
}

run "periodic_only_fields_are_omitted_for_continuous" {
  variables {
    backup_type = "Continuous"
    backup_tier = "Continuous30Days"
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.backup[0].tier == "Continuous30Days"
    error_message = "tier must be sent when backup_type is Continuous."
  }

  # An unset number renders as 0, which is exactly what the provider reads as
  # "not configured" before it rejects a Continuous account carrying Periodic
  # settings.
  assert {
    condition     = azurerm_cosmosdb_account.this.backup[0].interval_in_minutes == 0
    error_message = "interval_in_minutes is Periodic-only and must not be sent for Continuous backup."
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.backup[0].retention_in_hours == 0
    error_message = "retention_in_hours is Periodic-only and must not be sent for Continuous backup."
  }
}

run "periodic_fields_are_sent_for_periodic" {
  variables {
    backup_type                = "Periodic"
    backup_interval_in_minutes = 120
    backup_retention_in_hours  = 48
    backup_storage_redundancy  = "Zone"
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.backup[0].interval_in_minutes == 120
    error_message = "interval_in_minutes must be sent when backup_type is Periodic."
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.backup[0].retention_in_hours == 48
    error_message = "retention_in_hours must be sent when backup_type is Periodic."
  }

  assert {
    condition     = azurerm_cosmosdb_account.this.backup[0].storage_redundancy == "Zone"
    error_message = "storage_redundancy must be sent when backup_type is Periodic."
  }
}

# Note: that tier is dropped for Periodic accounts, and storage_redundancy for
# Continuous ones, cannot be asserted here. Both are Optional+Computed, so a
# mocked provider invents a value for them whenever the module leaves them
# unset, which is indistinguishable from the module having set one.
