output "id" {
  description = "ID of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.id
}

output "name" {
  description = "Name of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.name
}

output "endpoint" {
  description = "Endpoint URL used to connect to the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "primary_key" {
  description = "Primary master key for the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.primary_key
  sensitive   = true
}
