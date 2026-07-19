# terraform-azurerm-cosmosdb

Terraform module that manages an [Azure](https://azure.microsoft.com/) Cosmos DB
account. It provisions a single account with a configurable consistency level
and primary write region, supports adding further geo-replicated regions, and
exposes the endpoint and primary key.

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

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0   |

## Inputs

| Name                               | Description                                                            | Type           | Default              | Required |
|------------------------------------|------------------------------------------------------------------------|----------------|----------------------|:--------:|
| `name`                             | Name of the Cosmos DB account. Globally unique.                        | `string`       | n/a                  |   yes    |
| `resource_group_name`              | Name of the resource group in which to create the account.             | `string`       | n/a                  |   yes    |
| `location`                         | Azure region of the account's primary (write) region.                  | `string`       | n/a                  |   yes    |
| `offer_type`                       | Offer type of the Cosmos DB account.                                   | `string`       | `"Standard"`         |    no    |
| `kind`                             | Kind of Cosmos DB account. GlobalDocumentDB or MongoDB.                | `string`       | `"GlobalDocumentDB"` |    no    |
| `consistency_level`                | Default consistency level.                                             | `string`       | `"Session"`          |    no    |
| `max_interval_in_seconds`          | Max staleness interval, BoundedStaleness only.                        | `number`       | `300`                |    no    |
| `max_staleness_prefix`             | Max stale requests tolerated, BoundedStaleness only.                  | `number`       | `100000`             |    no    |
| `automatic_failover_enabled`       | Whether automatic failover between regions is enabled.                 | `bool`         | `true`               |    no    |
| `multiple_write_locations_enabled` | Whether multi-region writes are enabled.                               | `bool`         | `false`              |    no    |
| `additional_geo_locations`         | Additional read/write regions beyond the primary.                      | `list(object)` | `[]`                 |    no    |
| `tags`                             | Map of tags applied to the account.                                    | `map(string)`  | `{}`                 |    no    |

## Outputs

| Name          | Description                                     |
|---------------|-------------------------------------------------|
| `id`          | ID of the Cosmos DB account.                    |
| `name`        | Name of the Cosmos DB account.                  |
| `endpoint`    | Endpoint URL to connect to the account.         |
| `primary_key` | Primary master key (sensitive).                 |

## License

[MIT](LICENSE)
