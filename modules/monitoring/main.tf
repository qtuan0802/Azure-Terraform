# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                = var.log_analytics_sku
  retention_in_days   = var.retention_in_days
  
  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = var.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  
  tags = var.tags
}

# Action Group for Notifications
resource "azurerm_monitor_action_group" "main" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name
  
  dynamic "email_receiver" {
    for_each = var.email_receivers
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email_address
    }
  }
  
  dynamic "sms_receiver" {
    for_each = var.sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }
  
  dynamic "webhook_receiver" {
    for_each = var.webhook_receivers
    content {
      name                    = webhook_receiver.value.name
      service_uri            = webhook_receiver.value.service_uri
      use_common_alert_schema = webhook_receiver.value.use_common_alert_schema
    }
  }
  
  tags = var.tags
}

# Storage Account Monitoring Alerts
resource "azurerm_monitor_metric_alert" "storage_availability" {
  count               = var.storage_account_id != null ? 1 : 0
  name                = "storage-availability-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = [var.storage_account_id]
  
  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "storage_capacity" {
  count               = var.storage_account_id != null ? 1 : 0
  name                = "storage-capacity-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = [var.storage_account_id]
  
  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "UsedCapacity"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.storage_capacity_threshold_gb * 1024 * 1024 * 1024
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = var.tags
}

# Key Vault Monitoring Alerts
resource "azurerm_monitor_metric_alert" "keyvault_availability" {
  count               = var.key_vault_id != null ? 1 : 0
  name                = "keyvault-availability-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = [var.key_vault_id]
  
  criteria {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = var.tags
}

# Data Factory Monitoring Alerts
resource "azurerm_monitor_metric_alert" "datafactory_failed_runs" {
  count               = var.data_factory_id != null ? 1 : 0
  name                = "datafactory-failed-runs-${var.environment}"
  resource_group_name = var.resource_group_name
  scopes              = [var.data_factory_id]
  
  criteria {
    metric_namespace = "Microsoft.DataFactory/datafactories"
    metric_name      = "FailedRuns"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.datafactory_failed_runs_threshold
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = var.tags
}

# Dashboard for Fabric Monitoring
resource "azurerm_portal_dashboard" "fabric_dashboard" {
  count               = var.create_dashboard ? 1 : 0
  name                = "fabric-dashboard-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          "0" = {
            position = {
              x = 0
              y = 0
              rowSpan = 4
              colSpan = 6
            }
            metadata = {
              inputs = [{
                name = "resourceTypeMode"
                isOptional = true
              }, {
                name = "ComponentId"
                isOptional = true
              }]
              type = "Extension/HubsExtension/PartType/MonitorChartPart"
              settings = {}
            }
          }
          "1" = {
            position = {
              x = 6
              y = 0
              rowSpan = 4
              colSpan = 6
            }
            metadata = {
              inputs = []
              type = "Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart"
              settings = {}
            }
          }
        }
      }
    }
    metadata = {
      model = {
        timeRange = {
          value = {
            relative = {
              duration = 24
              timeUnit = 1
            }
          }
          type = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        }
      }
    }
  })
  
  tags = var.tags
}

# Diagnostic Settings for Resources
resource "azurerm_monitor_diagnostic_setting" "storage" {
  count              = var.storage_account_id != null ? 1 : 0
  name               = "storage-diagnostics"
  target_resource_id = var.storage_account_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  dynamic "enabled_log" {
    for_each = var.storage_diagnostic_logs
    content {
      category = enabled_log.value
    }
  }
  
  enabled_log {
    category = "Transaction"
  }
}

resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  count              = var.key_vault_id != null ? 1 : 0
  name               = "keyvault-diagnostics"
  target_resource_id = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  dynamic "enabled_log" {
    for_each = var.keyvault_diagnostic_logs
    content {
      category = enabled_log.value
    }
  }
  
  enabled_log {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "datafactory" {
  count              = var.data_factory_id != null ? 1 : 0
  name               = "datafactory-diagnostics"
  target_resource_id = var.data_factory_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  dynamic "enabled_log" {
    for_each = var.datafactory_diagnostic_logs
    content {
      category = enabled_log.value
    }
  }
  
  enabled_log {
    category = "AllMetrics"
  }
}