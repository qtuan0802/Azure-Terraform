output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = azurerm_application_insights.main.id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of the Application Insights instance"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string of the Application Insights instance"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "action_group_id" {
  description = "ID of the action group"
  value       = azurerm_monitor_action_group.main.id
}

output "action_group_name" {
  description = "Name of the action group"
  value       = azurerm_monitor_action_group.main.name
}

output "dashboard_id" {
  description = "ID of the Azure Portal dashboard."
  value       = var.create_dashboard ? azurerm_portal_dashboard.fabric_dashboard[0].id : null
}

output "dashboard_url" {
  description = "URL of the Azure Portal dashboard."
  value       = var.create_dashboard ? "https://portal.azure.com/#dashboard/private${azurerm_portal_dashboard.fabric_dashboard[0].id}" : null
}

// output "dashboard_id" {
//   description = "ID of the Azure Portal dashboard."
//   value       = var.create_dashboard ? azurerm_dashboard.fabric_dashboard[0].id : null
// }

// output "dashboard_url" {
//   description = "URL of the Azure Portal dashboard."
//   value       = var.create_dashboard ? "https://portal.azure.com/#dashboard/private${azurerm_dashboard.fabric_dashboard[0].id}" : null
// }