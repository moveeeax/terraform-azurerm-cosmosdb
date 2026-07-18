variable "name" {
  description = "Name of the Cosmos DB account. Must be globally unique."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the account."
  type        = string
}

variable "location" {
  description = "Azure region of the account's primary (write) region."
  type        = string
}

variable "offer_type" {
  description = "Offer type of the Cosmos DB account. Standard is currently the only value."
  type        = string
  default     = "Standard"
}

variable "kind" {
  description = "Kind of Cosmos DB account. One of GlobalDocumentDB or MongoDB."
  type        = string
  default     = "GlobalDocumentDB"
}

variable "consistency_level" {
  description = "Default consistency level. One of Eventual, Session, BoundedStaleness, Strong or ConsistentPrefix."
  type        = string
  default     = "Session"
}

variable "max_interval_in_seconds" {
  description = "Maximum staleness interval in seconds, only used when consistency_level is BoundedStaleness."
  type        = number
  default     = 300
}

variable "max_staleness_prefix" {
  description = "Maximum number of stale requests tolerated, only used when consistency_level is BoundedStaleness."
  type        = number
  default     = 100000
}

variable "automatic_failover_enabled" {
  description = "Whether automatic failover between regions is enabled."
  type        = bool
  default     = true
}

variable "multiple_write_locations_enabled" {
  description = "Whether multi-region writes are enabled."
  type        = bool
  default     = false
}

variable "additional_geo_locations" {
  description = "Additional read/write regions beyond the primary, each with a location and failover priority."
  type = list(object({
    location          = string
    failover_priority = number
  }))
  default = []
}

variable "tags" {
  description = "Map of tags applied to the account."
  type        = map(string)
  default     = {}
}
