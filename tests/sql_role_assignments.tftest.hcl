# Data-plane (SQL) role assignments. The mock gives the account a well-formed
# ID so the role definition and scope IDs the module builds from it can be
# compared exactly.
#
# `mock_provider` requires Terraform >= 1.7 (or OpenTofu >= 1.7) to run.

mock_provider "azurerm" {
  mock_resource "azurerm_cosmosdb_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.DocumentDB/databaseAccounts/example-cosmos01"
    }
  }
}

variables {
  name                = "example-cosmos01"
  resource_group_name = "example-rg"
  location            = "eastus"
}

run "no_role_assignments_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_cosmosdb_sql_role_assignment.this) == 0
    error_message = "No SQL role assignments may be created unless sql_role_assignments is set."
  }
}

run "builtin_roles_map_to_fixed_definition_ids" {
  variables {
    sql_role_assignments = {
      app = {
        principal_id = "11111111-1111-1111-1111-111111111111"
        role         = "contributor"
      }
      reporting = {
        principal_id = "22222222-2222-2222-2222-222222222222"
        role         = "reader"
        scope        = "/dbs/app/colls/orders"
      }
    }
  }

  assert {
    condition     = azurerm_cosmosdb_sql_role_assignment.this["app"].role_definition_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.DocumentDB/databaseAccounts/example-cosmos01/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
    error_message = "contributor must map to the Cosmos DB Built-in Data Contributor role (...0002)."
  }

  assert {
    condition     = azurerm_cosmosdb_sql_role_assignment.this["reporting"].role_definition_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.DocumentDB/databaseAccounts/example-cosmos01/sqlRoleDefinitions/00000000-0000-0000-0000-000000000001"
    error_message = "reader must map to the Cosmos DB Built-in Data Reader role (...0001)."
  }

  assert {
    condition     = azurerm_cosmosdb_sql_role_assignment.this["app"].scope == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.DocumentDB/databaseAccounts/example-cosmos01"
    error_message = "A null scope must cover the whole account."
  }

  assert {
    condition     = azurerm_cosmosdb_sql_role_assignment.this["reporting"].scope == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.DocumentDB/databaseAccounts/example-cosmos01/dbs/app/colls/orders"
    error_message = "A relative scope must be appended to the account ID."
  }

  assert {
    condition     = azurerm_cosmosdb_sql_role_assignment.this["app"].account_name == "example-cosmos01" && azurerm_cosmosdb_sql_role_assignment.this["app"].resource_group_name == "example-rg"
    error_message = "Role assignments must target this module's account."
  }
}

run "custom_role_definition_id_is_passed_through" {
  variables {
    sql_role_assignments = {
      custom = {
        principal_id = "33333333-3333-3333-3333-333333333333"
        role         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.DocumentDB/databaseAccounts/example-cosmos01/sqlRoleDefinitions/aaaaaaaa-0000-0000-0000-000000000000"
      }
    }
  }

  assert {
    condition     = azurerm_cosmosdb_sql_role_assignment.this["custom"].role_definition_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.DocumentDB/databaseAccounts/example-cosmos01/sqlRoleDefinitions/aaaaaaaa-0000-0000-0000-000000000000"
    error_message = "A full role definition ID must be used as given."
  }
}

run "rejects_non_guid_principal_id" {
  command = plan

  variables {
    sql_role_assignments = {
      app = {
        principal_id = "my-app"
        role         = "reader"
      }
    }
  }

  expect_failures = [var.sql_role_assignments]
}

run "rejects_unknown_role_name" {
  command = plan

  variables {
    sql_role_assignments = {
      app = {
        principal_id = "11111111-1111-1111-1111-111111111111"
        role         = "owner"
      }
    }
  }

  expect_failures = [var.sql_role_assignments]
}

run "rejects_absolute_or_malformed_scope" {
  command = plan

  variables {
    sql_role_assignments = {
      app = {
        principal_id = "11111111-1111-1111-1111-111111111111"
        role         = "reader"
        scope        = "dbs/app"
      }
    }
  }

  expect_failures = [var.sql_role_assignments]
}

run "rejects_sql_roles_on_mongodb_account" {
  command = plan

  variables {
    kind = "MongoDB"
    sql_role_assignments = {
      app = {
        principal_id = "11111111-1111-1111-1111-111111111111"
        role         = "reader"
      }
    }
  }

  expect_failures = [azurerm_cosmosdb_sql_role_assignment.this]
}
