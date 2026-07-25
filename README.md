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
  source = "github.com/moveeeax/terraform-azurerm-cosmosdb"

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

| Name      | Version   |
|-----------|-----------|
| terraform | >= 1.5    |
| azurerm   | >= 3.99.0 |

`3.99.0` is not a preference, it is the floor: it is the first release in which
`azurerm_cosmosdb_account` accepts `automatic_failover_enabled` and
`multiple_write_locations_enabled`. On `3.98.0` and older, `terraform validate`
fails with `Unsupported argument`. The module is validated against `3.99.0`
through `4.x`.

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
| `minimal_tls_version`              | Minimum accepted TLS version. Tls, Tls11 or Tls12.                       | `string`       | `"Tls12"`            |    no    |
| `backup_type`                      | Backup mode. Periodic or Continuous.                                     | `string`       | `"Periodic"`         |    no    |
| `backup_tier`                      | Continuous retention tier, Continuous only.                              | `string`       | `"Continuous7Days"`  |    no    |
| `backup_interval_in_minutes`       | Interval between periodic backups, Periodic only.                        | `number`       | `240`                |    no    |
| `backup_retention_in_hours`        | Periodic backup retention, Periodic only.                                | `number`       | `8`                  |    no    |
| `backup_storage_redundancy`        | Periodic backup redundancy. Geo, Local or Zone. Periodic only.           | `string`       | `"Geo"`              |    no    |
| `tags`                             | Map of tags applied to the account.                                      | `map(string)`  | `{}`                 |    no    |

## Outputs

| Name          | Description                                     |
|---------------|-------------------------------------------------|
| `id`          | ID of the Cosmos DB account.                    |
| `name`        | Name of the Cosmos DB account.                  |
| `endpoint`    | Endpoint URL to connect to the account.         |
| `primary_key` | Primary master key (sensitive).                 |

`primary_key` is only usable while `local_authentication_disabled` is `false`.

## Tests

```
terraform test
```

The suite mocks the `azurerm` provider, so it needs no Azure subscription, no
credentials and no network beyond fetching the provider.

## License

[MIT](LICENSE)
