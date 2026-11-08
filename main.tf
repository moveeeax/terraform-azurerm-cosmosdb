locals {
  # max_interval_in_seconds / max_staleness_prefix are only accepted by the API
  # when the consistency level is BoundedStaleness. Sending them for any other
  # level is an apply-time error, so they are nulled out instead.
  bounded_staleness = var.consistency_level == "BoundedStaleness"

  # Likewise, interval_in_minutes / retention_in_hours / storage_redundancy are
  # Periodic-only, and tier is Continuous-only.
  periodic_backup = var.backup_type == "Periodic"

  additional_locations = [for g in var.additional_geo_locations : lower(replace(g.location, " ", ""))]
  primary_location     = lower(replace(var.location, " ", ""))

  # Azure widens the BoundedStaleness bounds once the account spans more than
  # one region: prefix >= 100000 and interval >= 300.
  multi_region = length(var.additional_geo_locations) > 0

  # IDs of the Cosmos DB built-in data-plane roles. They are the same fixed
  # GUIDs on every account; only the account prefix differs.
  # https://learn.microsoft.com/azure/cosmos-db/nosql/security/reference-data-plane-roles
  sql_builtin_roles = {
    reader      = "00000000-0000-0000-0000-000000000001"
    contributor = "00000000-0000-0000-0000-000000000002"
  }
}

resource "azurerm_cosmosdb_account" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  offer_type          = var.offer_type
  kind                = var.kind

  automatic_failover_enabled       = var.automatic_failover_enabled
  multiple_write_locations_enabled = var.multiple_write_locations_enabled

  public_network_access_enabled = var.public_network_access_enabled
  local_authentication_enabled  = !var.local_authentication_disabled
  minimal_tls_version           = var.minimal_tls_version

  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = local.bounded_staleness ? var.max_interval_in_seconds : null
    max_staleness_prefix    = local.bounded_staleness ? var.max_staleness_prefix : null
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  dynamic "geo_location" {
    for_each = var.additional_geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
    }
  }

  backup {
    type                = var.backup_type
    tier                = local.periodic_backup ? null : var.backup_tier
    interval_in_minutes = local.periodic_backup ? var.backup_interval_in_minutes : null
    retention_in_hours  = local.periodic_backup ? var.backup_retention_in_hours : null
    storage_redundancy  = local.periodic_backup ? var.backup_storage_redundancy : null
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = !contains(local.additional_locations, local.primary_location)
      error_message = "additional_geo_locations must not repeat the primary region (var.location); it is already added with failover_priority 0."
    }

    precondition {
      condition     = !var.multiple_write_locations_enabled || local.multi_region
      error_message = "multiple_write_locations_enabled requires at least one entry in additional_geo_locations; multi-region writes need two or more regions."
    }

    precondition {
      condition     = !(local.bounded_staleness && local.multi_region) || var.max_staleness_prefix >= 100000
      error_message = "With BoundedStaleness across more than one region, max_staleness_prefix must be at least 100000."
    }

    precondition {
      condition     = !(local.bounded_staleness && local.multi_region) || var.max_interval_in_seconds >= 300
      error_message = "With BoundedStaleness across more than one region, max_interval_in_seconds must be at least 300."
    }
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "this" {
  for_each = var.sql_role_assignments

  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  principal_id        = each.value.principal_id
  scope               = "${azurerm_cosmosdb_account.this.id}${each.value.scope != null ? each.value.scope : ""}"

  role_definition_id = (
    contains(keys(local.sql_builtin_roles), each.value.role)
    ? "${azurerm_cosmosdb_account.this.id}/sqlRoleDefinitions/${local.sql_builtin_roles[each.value.role]}"
    : each.value.role
  )

  lifecycle {
    # SQL role assignments only exist on NoSQL (GlobalDocumentDB) accounts.
    # MongoDB accounts use mongo role/user definitions instead.
    precondition {
      condition     = var.kind == "GlobalDocumentDB"
      error_message = "sql_role_assignments require kind = \"GlobalDocumentDB\" (the NoSQL API); MongoDB and Parse accounts do not support Cosmos DB SQL role assignments."
    }
  }
}
