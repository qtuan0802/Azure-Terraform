output "data_factory_id" {
  description = "ID of the Data Factory"
  value       = azurerm_data_factory.main.id
}

output "data_factory_name" {
  description = "Name of the Data Factory"
  value       = azurerm_data_factory.main.name
}

output "data_factory_identity_principal_id" {
  description = "Principal ID of the Data Factory managed identity"
  value       = azurerm_data_factory.main.identity[0].principal_id
}

output "data_factory_identity_tenant_id" {
  description = "Tenant ID of the Data Factory managed identity"
  value       = azurerm_data_factory.main.identity[0].tenant_id
}

output "integration_runtime_auth_key_1" {
  description = "First authentication key for self-hosted integration runtime"
  value       = var.enable_self_hosted_ir ? azurerm_data_factory_integration_runtime_self_hosted.main[0].primary_authorization_key : null
  sensitive   = true
}

output "integration_runtime_auth_key_2" {
  description = "Second authentication key for self-hosted integration runtime"
  value       = var.enable_self_hosted_ir ? azurerm_data_factory_integration_runtime_self_hosted.main[0].secondary_authorization_key : null
  sensitive   = true
}