variable "name" {
  description = "Name of the Cosmos DB account. Must be globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,48}[a-z0-9]$", var.name))
    error_message = "name must be 3-50 characters of lowercase letters, numbers and hyphens, and may not start or end with a hyphen."
  }
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

  validation {
    condition     = var.offer_type == "Standard"
    error_message = "offer_type must be \"Standard\"."
  }
}

variable "kind" {
  description = "Kind of Cosmos DB account. One of GlobalDocumentDB, MongoDB or Parse."
  type        = string
  default     = "GlobalDocumentDB"

  validation {
    condition     = contains(["GlobalDocumentDB", "MongoDB", "Parse"], var.kind)
    error_message = "kind must be one of GlobalDocumentDB, MongoDB or Parse."
  }
}

variable "consistency_level" {
  description = "Default consistency level. One of Eventual, Session, BoundedStaleness, Strong or ConsistentPrefix."
  type        = string
  default     = "Session"

  validation {
    condition     = contains(["Eventual", "Session", "BoundedStaleness", "Strong", "ConsistentPrefix"], var.consistency_level)
    error_message = "consistency_level must be one of Eventual, Session, BoundedStaleness, Strong or ConsistentPrefix."
  }
}

variable "max_interval_in_seconds" {
  description = "Maximum staleness interval in seconds. Only sent when consistency_level is BoundedStaleness; ignored otherwise."
  type        = number
  default     = 300

  validation {
    condition     = var.max_interval_in_seconds >= 5 && var.max_interval_in_seconds <= 86400
    error_message = "max_interval_in_seconds must be between 5 and 86400."
  }
}

variable "max_staleness_prefix" {
  description = "Maximum number of stale requests tolerated. Only sent when consistency_level is BoundedStaleness; ignored otherwise."
  type        = number
  default     = 100000

  validation {
    condition     = var.max_staleness_prefix >= 10 && var.max_staleness_prefix <= 2147483647
    error_message = "max_staleness_prefix must be between 10 and 2147483647."
  }
}

variable "automatic_failover_enabled" {
  description = "Whether automatic failover between regions is enabled."
  type        = bool
  default     = true
}

variable "multiple_write_locations_enabled" {
  description = "Whether multi-region writes are enabled. Requires at least one entry in additional_geo_locations."
  type        = bool
  default     = false
}

variable "additional_geo_locations" {
  description = "Additional read/write regions beyond the primary, each with a location and a failover priority of 1 or higher."
  type = list(object({
    location          = string
    failover_priority = number
  }))
  default = []

  validation {
    condition     = alltrue([for g in var.additional_geo_locations : g.failover_priority >= 1])
    error_message = "failover_priority 0 is reserved for the primary region; additional_geo_locations must use 1 or higher."
  }

  validation {
    condition     = length(distinct([for g in var.additional_geo_locations : g.failover_priority])) == length(var.additional_geo_locations)
    error_message = "failover_priority values in additional_geo_locations must be unique."
  }

  validation {
    condition     = length(distinct([for g in var.additional_geo_locations : lower(replace(g.location, " ", ""))])) == length(var.additional_geo_locations)
    error_message = "each region may appear only once in additional_geo_locations."
  }
}

variable "public_network_access_enabled" {
  description = "Whether the account is reachable over the public internet. Defaults to false; reach the account through a private endpoint, or set this to true and pair it with a firewall."
  type        = bool
  default     = false
}

variable "local_authentication_disabled" {
  description = "Whether key-based (local) authentication is disabled, leaving Microsoft Entra ID RBAC as the only way in. Enabling this makes the primary_key output unusable, so it defaults to false; turn it on once role assignments are in place."
  type        = bool
  default     = false
}

variable "minimal_tls_version" {
  description = "Minimum TLS version accepted by the account. One of Tls, Tls11 or Tls12."
  type        = string
  default     = "Tls12"

  validation {
    condition     = contains(["Tls", "Tls11", "Tls12"], var.minimal_tls_version)
    error_message = "minimal_tls_version must be one of Tls, Tls11 or Tls12."
  }
}

variable "backup_type" {
  description = "Backup mode of the account. Either Periodic or Continuous."
  type        = string
  default     = "Periodic"

  validation {
    condition     = contains(["Periodic", "Continuous"], var.backup_type)
    error_message = "backup_type must be either Periodic or Continuous."
  }
}

variable "backup_tier" {
  description = "Retention tier for continuous backup. One of Continuous7Days or Continuous30Days. Only sent when backup_type is Continuous; ignored otherwise."
  type        = string
  default     = "Continuous7Days"

  validation {
    condition     = contains(["Continuous7Days", "Continuous30Days"], var.backup_tier)
    error_message = "backup_tier must be either Continuous7Days or Continuous30Days."
  }
}

variable "backup_interval_in_minutes" {
  description = "Interval between periodic backups, in minutes. Only sent when backup_type is Periodic; ignored otherwise."
  type        = number
  default     = 240

  validation {
    condition     = var.backup_interval_in_minutes >= 60 && var.backup_interval_in_minutes <= 1440
    error_message = "backup_interval_in_minutes must be between 60 and 1440."
  }
}

variable "backup_retention_in_hours" {
  description = "How long periodic backups are kept, in hours. Only sent when backup_type is Periodic; ignored otherwise."
  type        = number
  default     = 8

  validation {
    condition     = var.backup_retention_in_hours >= 8 && var.backup_retention_in_hours <= 720
    error_message = "backup_retention_in_hours must be between 8 and 720."
  }
}

variable "backup_storage_redundancy" {
  description = "Redundancy of the periodic backup storage. One of Geo, Local or Zone. Only sent when backup_type is Periodic; ignored otherwise."
  type        = string
  default     = "Geo"

  validation {
    condition     = contains(["Geo", "Local", "Zone"], var.backup_storage_redundancy)
    error_message = "backup_storage_redundancy must be one of Geo, Local or Zone."
  }
}

variable "tags" {
  description = "Map of tags applied to the account."
  type        = map(string)
  default     = {}
}
