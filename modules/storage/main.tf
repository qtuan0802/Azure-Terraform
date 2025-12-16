# Storage Account for OneLake integration
resource "azurerm_storage_account" "main" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier
  
  # Security settings
  https_traffic_only_enabled      = var.enable_https_traffic_only
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  
  # Blob properties
  blob_properties {
    # CORS rules for Fabric integration
    dynamic "cors_rule" {
      for_each = var.cors_rules
      content {
        allowed_headers    = cors_rule.value.allowed_headers
        allowed_methods    = cors_rule.value.allowed_methods
        allowed_origins    = cors_rule.value.allowed_origins
        exposed_headers    = cors_rule.value.exposed_headers
        max_age_in_seconds = cors_rule.value.max_age_in_seconds
      }
    }
    
    # Change feed disabled for Data Lake Gen2 compatibility
    change_feed_enabled = false
    change_feed_retention_in_days = null
    
    # Versioning
    versioning_enabled = var.enable_versioning
    
    
    # Container delete retention policy
    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
  }
  
  # Network rules
  network_rules {
    default_action             = var.network_rules.default_action
    ip_rules                   = var.network_rules.ip_rules
    virtual_network_subnet_ids = var.network_rules.virtual_network_subnet_ids
    bypass                     = var.network_rules.bypass
  }
  
  # Identity
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

# Containers for Fabric data
resource "azurerm_storage_container" "fabric_containers" {
  for_each              = var.containers
  name                  = each.key
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = each.value.access_type
}

# Data Lake Gen2 filesystem (if enabled)
resource "azurerm_storage_data_lake_gen2_filesystem" "fabric_filesystem" {
  for_each           = var.enable_data_lake_gen2 ? var.data_lake_filesystems : {}
  name               = each.key
  storage_account_id = azurerm_storage_account.main.id
  
  dynamic "ace" {
    for_each = each.value.ace != null ? each.value.ace : []
    content {
      type        = ace.value.type
      scope       = ace.value.scope
      id          = ace.value.id
      permissions = ace.value.permissions
    }
  }
}

# Private endpoint for storage (if enabled)
resource "azurerm_private_endpoint" "storage" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  
  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_ids != null ? [1] : []
    content {
      name                 = "pdz-group-${var.name}"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }
  
  tags = var.tags
}

# Storage account management policy
resource "azurerm_storage_management_policy" "main" {
  count              = var.enable_lifecycle_management ? 1 : 0
  storage_account_id = azurerm_storage_account.main.id
  
  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.value.name
      enabled = rule.value.enabled
      
      filters {
        prefix_match = rule.value.prefix_match
        blob_types   = rule.value.blob_types
      }
      
      actions {
        base_blob {
          tier_to_cool_after_days_since_modification_greater_than    = rule.value.cool_after_days
          tier_to_archive_after_days_since_modification_greater_than = rule.value.archive_after_days
          delete_after_days_since_modification_greater_than          = rule.value.delete_after_days
        }
        
        dynamic "snapshot" {
          for_each = rule.value.snapshot_delete_after_days != null ? [1] : []
          content {
            delete_after_days_since_creation_greater_than = rule.value.snapshot_delete_after_days
          }
        }
        
        dynamic "version" {
          for_each = rule.value.version_delete_after_days != null ? [1] : []
          content {
            delete_after_days_since_creation = rule.value.version_delete_after_days
          }
        }
      }
    }
  }
}