output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary DFS endpoint for Data Lake Gen2"
  value       = azurerm_storage_account.main.primary_dfs_endpoint
}

output "primary_web_endpoint" {
  description = "Primary web endpoint"
  value       = azurerm_storage_account.main.primary_web_endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key"
  value       = azurerm_storage_account.main.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "identity_principal_id" {
  description = "Principal ID of the storage account managed identity"
  value       = azurerm_storage_account.main.identity[0].principal_id
}

output "containers" {
  description = "Created storage containers"
  value = {
    for k, v in azurerm_storage_container.fabric_containers : k => {
      name = v.name
      url  = "${azurerm_storage_account.main.primary_blob_endpoint}${v.name}"
    }
  }
}

output "data_lake_filesystems" {
  description = "Created Data Lake Gen2 filesystems"
  value = var.enable_data_lake_gen2 ? {
    for k, v in azurerm_storage_data_lake_gen2_filesystem.fabric_filesystem : k => {
      name = v.name
      url  = "${azurerm_storage_account.main.primary_dfs_endpoint}${v.name}"
    }
  } : {}
}

output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.storage[0].id : null
}