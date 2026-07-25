# Negative tests: every one of these would otherwise only fail at apply time,
# after Terraform has already started talking to Azure.
#
# `mock_provider` requires Terraform >= 1.7 (or OpenTofu >= 1.7) to run.

mock_provider "azurerm" {}

variables {
  name                = "example-cosmos01"
  resource_group_name = "example-rg"
  location            = "eastus"
}

run "rejects_invalid_consistency_level" {
  command = plan

  variables {
    consistency_level = "session"
  }

  expect_failures = [var.consistency_level]
}

run "rejects_invalid_kind" {
  command = plan

  variables {
    kind = "DocumentDB"
  }

  expect_failures = [var.kind]
}

run "rejects_invalid_tls_version" {
  command = plan

  variables {
    minimal_tls_version = "TLS1_2"
  }

  expect_failures = [var.minimal_tls_version]
}

run "rejects_invalid_backup_type" {
  command = plan

  variables {
    backup_type = "periodic"
  }

  expect_failures = [var.backup_type]
}

run "rejects_invalid_backup_storage_redundancy" {
  command = plan

  variables {
    backup_storage_redundancy = "GRS"
  }

  expect_failures = [var.backup_storage_redundancy]
}

run "rejects_out_of_range_backup_retention" {
  command = plan

  variables {
    backup_retention_in_hours = 4
  }

  expect_failures = [var.backup_retention_in_hours]
}

run "rejects_invalid_account_name" {
  command = plan

  variables {
    name = "Example_Cosmos"
  }

  expect_failures = [var.name]
}

run "rejects_failover_priority_zero_on_additional_region" {
  command = plan

  variables {
    additional_geo_locations = [
      { location = "westus", failover_priority = 0 },
    ]
  }

  expect_failures = [var.additional_geo_locations]
}

run "rejects_duplicate_failover_priority" {
  command = plan

  variables {
    additional_geo_locations = [
      { location = "westus", failover_priority = 1 },
      { location = "westeurope", failover_priority = 1 },
    ]
  }

  expect_failures = [var.additional_geo_locations]
}

run "rejects_primary_region_repeated_as_additional" {
  command = plan

  variables {
    additional_geo_locations = [
      { location = "East US", failover_priority = 1 },
    ]
  }

  expect_failures = [azurerm_cosmosdb_account.this]
}

run "rejects_multi_write_without_extra_region" {
  command = plan

  variables {
    multiple_write_locations_enabled = true
  }

  expect_failures = [azurerm_cosmosdb_account.this]
}

run "rejects_bounded_staleness_below_multi_region_minimum" {
  command = plan

  variables {
    consistency_level    = "BoundedStaleness"
    max_staleness_prefix = 100
    additional_geo_locations = [
      { location = "westus", failover_priority = 1 },
    ]
  }

  expect_failures = [azurerm_cosmosdb_account.this]
}
