# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [2.1.0] - 2026-11-08

### Added

- `sql_role_assignments`: Cosmos DB data-plane role assignments
  (`azurerm_cosmosdb_sql_role_assignment`) for NoSQL accounts. `role` takes
  `reader` or `contributor` (the built-in Data Reader and Data Contributor roles)
  or the full ID of a custom SQL role definition; `scope` narrows an assignment
  to a database or container. Rejected at plan time on `MongoDB` and `Parse`
  accounts. Defaults to `{}`, so existing plans do not change.
- `sql_role_assignment_ids` output.

## [2.0.0] - 2026-11-03

Support for `azurerm` 5.x; see the README section "Upgrading from v1".

[Unreleased]: https://github.com/moveeeax/terraform-azurerm-cosmosdb/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/moveeeax/terraform-azurerm-cosmosdb/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/moveeeax/terraform-azurerm-cosmosdb/compare/v1.0.1...v2.0.0
