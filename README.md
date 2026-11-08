# terraform-azurerm-cosmosdb

Terraform module that manages an [Azure](https://azure.microsoft.com/) Cosmos DB
account. It provisions a single account with a configurable consistency level
and primary write region, supports adding further geo-replicated regions, and
exposes the endpoint and primary key.

The account is private by default: `public_network_access_enabled` defaults to
`false`, so reach it through a private endpoint unless you opt back in.

## Usage

```hcl
module "cosmosdb" {
  source = "github.com/moveeeax/terraform-azurerm-cosmosdb?ref=v2.0.0"

  name                = "prod-cosmos01"
  resource_group_name = "prod-rg"
  location            = "eastus"

  consistency_level = "Session"

  additional_geo_locations = [
    {
      location          = "westus"
      failover_priority = 1
    }
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.5           |
| azurerm   | >= 4.78.0, < 6.0 |

`4.78.0` is the floor: it is the first release in which `azurerm_cosmosdb_account`
accepts `local_authentication_enabled`, and `5.0` removed the older
`local_authentication_disabled`, so that is the only name that works on both
majors. The module is validated against `4.78.0`, `4.81.0`, `5.0.0` and `5.12.0`.

If you are still on `azurerm` `3.x` or `4.0`-`4.77`, stay on the `v1` line of
this module (`?ref=v1.0.1`), which is capped at `< 5.0`.

### Upgrading from v1

- Raise your `azurerm` constraint to at least `4.78.0`.
- `minimal_tls_version` now only accepts `Tls12`, the only value `azurerm` 5.x
  takes. If you set `Tls` or `Tls11`, remove it.
- The `local_authentication_disabled` input keeps its name and meaning; the module
  now passes it to the provider as `local_authentication_enabled`.

Running the test suite additionally needs Terraform (or OpenTofu) `>= 1.7`,
because it uses `mock_provider`. The module itself still works on `>= 1.5`.

## Notes on inputs that only apply in some configurations

The Cosmos DB API rejects a request that carries settings belonging to a mode it
is not in, so the module drops them for you rather than letting the apply fail
halfway:

- `max_interval_in_seconds` and `max_staleness_prefix` are only sent when
  `consistency_level` is `BoundedStaleness`.
- `backup_interval_in_minutes`, `backup_retention_in_hours` and
  `backup_storage_redundancy` are only sent when `backup_type` is `Periodic`.
- `backup_tier` is only sent when `backup_type` is `Continuous`.

Leaving those variables at their defaults while using another mode is therefore
safe — they are simply ignored.

## Data-plane role assignments

Azure RBAC role assignments (`azurerm_role_assignment`) do not grant access to
the data in a Cosmos DB account. Reading and writing items with Microsoft Entra
ID needs Cosmos DB SQL role assignments, which `sql_role_assignments` creates.
They are what keeps the account usable once `local_authentication_disabled` is
`true`.

```hcl
module "cosmosdb" {
  # source, name, resource_group_name, location as above

  local_authentication_disabled = true

  sql_role_assignments = {
    api = {
      principal_id = azurerm_user_assigned_identity.api.principal_id
      role         = "contributor"
    }
    reporting = {
      principal_id = "00000000-0000-0000-0000-000000000000"
      role         = "reader"
      scope        = "/dbs/app/colls/orders"
    }
  }
}
```

- `role` is `reader` (Cosmos DB Built-in Data Reader), `contributor` (Cosmos DB
  Built-in Data Contributor) or the full ID of a custom SQL role definition.
- `scope` is relative to the account: `/dbs/<database>` or
  `/dbs/<database>/colls/<container>`. Leave it unset to cover the whole account.
- Only `kind = "GlobalDocumentDB"` (the NoSQL API) supports these; the plan fails
  on `MongoDB` and `Parse` accounts.

Recommended: assign roles here, apply, move your clients to Entra ID auth, then
set `local_authentication_disabled = true`.

## IP firewall

The module does not expose `ip_range_filter`. Its type changed between provider
majors — `string` in `azurerm` 3.x, `set(string)` in 4.x — so exposing it would
pin the module to one of them. Use `public_network_access_enabled = false` with a
private endpoint, which is the stronger control anyway, or manage
`ip_range_filter` on an account created outside this module.

## Inputs

| Name                               | Description                                                              | Type           | Default              | Required |
|------------------------------------|--------------------------------------------------------------------------|----------------|----------------------|:--------:|
| `name`                             | Name of the Cosmos DB account. Globally unique.                          | `string`       | n/a                  |   yes    |
| `resource_group_name`              | Name of the resource group in which to create the account.               | `string`       | n/a                  |   yes    |
| `location`                         | Azure region of the account's primary (write) region.                    | `string`       | n/a                  |   yes    |
| `offer_type`                       | Offer type of the Cosmos DB account.                                     | `string`       | `"Standard"`         |    no    |
| `kind`                             | Kind of Cosmos DB account. GlobalDocumentDB, MongoDB or Parse.           | `string`       | `"GlobalDocumentDB"` |    no    |
| `consistency_level`                | Default consistency level.                                               | `string`       | `"Session"`          |    no    |
| `max_interval_in_seconds`          | Max staleness interval, BoundedStaleness only.                           | `number`       | `300`                |    no    |
| `max_staleness_prefix`             | Max stale requests tolerated, BoundedStaleness only.                     | `number`       | `100000`             |    no    |
| `automatic_failover_enabled`       | Whether automatic failover between regions is enabled.                   | `bool`         | `true`               |    no    |
| `multiple_write_locations_enabled` | Whether multi-region writes are enabled.                                 | `bool`         | `false`              |    no    |
| `additional_geo_locations`         | Additional read/write regions beyond the primary.                        | `list(object)` | `[]`                 |    no    |
| `public_network_access_enabled`    | Whether the account is reachable over the public internet.               | `bool`         | `false`              |    no    |
| `local_authentication_disabled`    | Disable key auth, leaving Entra ID RBAC as the only way in.              | `bool`         | `false`              |    no    |
| `minimal_tls_version`              | Minimum accepted TLS version. Only Tls12.                                | `string`       | `"Tls12"`            |    no    |
| `backup_type`                      | Backup mode. Periodic or Continuous.                                     | `string`       | `"Periodic"`         |    no    |
| `backup_tier`                      | Continuous retention tier, Continuous only.                              | `string`       | `"Continuous7Days"`  |    no    |
| `backup_interval_in_minutes`       | Interval between periodic backups, Periodic only.                        | `number`       | `240`                |    no    |
| `backup_retention_in_hours`        | Periodic backup retention, Periodic only.                                | `number`       | `8`                  |    no    |
| `backup_storage_redundancy`        | Periodic backup redundancy. Geo, Local or Zone. Periodic only.           | `string`       | `"Geo"`              |    no    |
| `sql_role_assignments`             | Data-plane SQL role assignments (NoSQL only). See above.                 | `map(object)`  | `{}`                 |    no    |
| `tags`                             | Map of tags applied to the account.                                      | `map(string)`  | `{}`                 |    no    |

## Outputs

| Name          | Description                                     |
|---------------|-------------------------------------------------|
| `id`          | ID of the Cosmos DB account.                    |
| `name`        | Name of the Cosmos DB account.                  |
| `endpoint`    | Endpoint URL to connect to the account.         |
| `primary_key` | Primary master key (sensitive).                 |
| `sql_role_assignment_ids` | IDs of the SQL role assignments, keyed like `sql_role_assignments`. |

`primary_key` is only usable while `local_authentication_disabled` is `false`.

## Tests

```
terraform test
```

The suite mocks the `azurerm` provider, so it needs no Azure subscription, no
credentials and no network beyond fetching the provider.

## License

[MIT](LICENSE)
