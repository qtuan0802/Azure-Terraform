variable "name" {
  description = "Name of the storage account"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 characters long and contain only lowercase letters and numbers."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location of the storage account"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be either 'Standard' or 'Premium'."
  }
}

variable "account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Invalid replication type."
  }
}

variable "account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"
  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Invalid account kind."
  }
}

variable "access_tier" {
  description = "Access tier for the storage account"
  type        = string
  default     = "Hot"
  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Access tier must be either 'Hot' or 'Cool'."
  }
}

# Security settings
variable "enable_https_traffic_only" {
  description = "Enable HTTPS traffic only"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "Invalid TLS version."
  }
}

variable "allow_nested_items_to_be_public" {
  description = "Allow nested items to be public"
  type        = bool
  default     = false
}

# Blob properties
variable "cors_rules" {
  description = "CORS rules for blob service"
  type = list(object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = []
}

variable "enable_change_feed" {
  description = "Enable change feed"
  type        = bool
  default     = false
}

variable "change_feed_retention_days" {
  description = "Change feed retention in days"
  type        = number
  default     = 7
}

variable "enable_versioning" {
  description = "Enable versioning"
  type        = bool
  default     = false
}

variable "delete_retention_days" {
  description = "Blob delete retention in days"
  type        = number
  default     = 7
}

variable "container_delete_retention_days" {
  description = "Container delete retention in days"
  type        = number
  default     = 7
}

# Network rules
variable "network_rules" {
  description = "Network rules for the storage account"
  type = object({
    default_action             = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
    bypass                     = list(string)
  })
  default = {
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = []
    bypass                     = ["AzureServices"]
  }
}

# Containers
variable "containers" {
  description = "Storage containers to create"
  type = map(object({
    access_type = string
  }))
  default = {
    "fabric-data" = {
      access_type = "private"
    }
    "fabric-logs" = {
      access_type = "private"
    }
  }
}

# Data Lake Gen2
variable "enable_data_lake_gen2" {
  description = "Enable Data Lake Gen2"
  type        = bool
  default     = true
}

variable "data_lake_filesystems" {
  description = "Data Lake Gen2 filesystems"
  type = map(object({
    ace = optional(list(object({
      type        = string
      scope       = string
      id          = string
      permissions = string
    })))
  }))
  default = {
    "fabric-datalake" = {
      ace = null
    }
  }
}

# Private endpoint
variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "Private DNS zone IDs"
  type        = list(string)
  default     = null
}

# Lifecycle management
variable "enable_lifecycle_management" {
  description = "Enable lifecycle management"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Lifecycle management rules"
  type = list(object({
    name                        = string
    enabled                     = bool
    prefix_match               = list(string)
    blob_types                 = list(string)
    cool_after_days            = optional(number)
    archive_after_days         = optional(number)
    delete_after_days          = optional(number)
    snapshot_delete_after_days = optional(number)
    version_delete_after_days  = optional(number)
  }))
  default = []
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}