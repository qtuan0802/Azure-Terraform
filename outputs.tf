# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.fabric.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.fabric.location
}

# Fabric Workspace Outputs (Existing workspace)
output "workspace_name" {
  description = "Name of the existing Fabric workspace"
  value       = local.workspace_name
}

output "workspace_url" {
  description = "URL to access Fabric workspace"
  value       = local.workspace_url
}

# Data Factory Outputs
output "data_factory_id" {
  description = "ID of the Data Factory"
  value       = var.enable_data_factory ? module.data_factory[0].data_factory_id : null
}

output "data_factory_name" {
  description = "Name of the Data Factory"
  value       = var.enable_data_factory ? module.data_factory[0].data_factory_name : null
}

# Key Vault Outputs
# output "key_vault_id" {
#   description = "ID of the Key Vault"
#   value       = module.key_vault_sapsfbatch
# }

# output "key_vault_name" {
#   description = "Name of the Key Vault"
#   value       = module.key_vault_sapsfbatch.key_vault_name
# }

# output "key_vault_uri" {
#   description = "URI of the Key Vault"
#   value       = module.key_vault_sapsfbatch.key_vault_uri
# }

# Storage Account Outputs
output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.storage_account.storage_account_id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage_account.storage_account_name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = module.storage_account.primary_blob_endpoint
}

output "storage_account_primary_dfs_endpoint" {
  description = "Primary DFS endpoint of the storage account for OneLake"
  value       = module.storage_account.primary_dfs_endpoint
}
