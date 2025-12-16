# App Service Plan
resource "azurerm_service_plan" "main" {
	name                = "asp-java-app-${var.environment}"
	resource_group_name = var.resource_group_name
	location            = var.location
	os_type             = "Linux"
	sku_name            = var.app_service_sku

	tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
	name                = "ai-java-app-${var.environment}"
	location            = var.location
	resource_group_name = var.resource_group_name
	application_type    = "web"

	tags = var.tags
}



# Reference shared Key Vault from root module
data "azurerm_key_vault" "shared" {
	name                = var.key_vault_name
	resource_group_name = var.key_vault_resource_group
}

# App Service
resource "azurerm_linux_web_app" "main" {
	name                = "app-java-${var.environment}-${var.suffix}"
	resource_group_name = var.resource_group_name
	location            = var.location
	service_plan_id     = azurerm_service_plan.main.id

	# Enable system-assigned managed identity
	identity {
		type = "SystemAssigned"
	}

	site_config {
		# Java configuration
		application_stack {
			java_server         = "TOMCAT"
			java_server_version = "9.0"
			java_version        = "17"
		}

		# Always on for production
		always_on = var.environment == "prod" ? true : false

		# Health check
		health_check_path                 = var.health_check_path
		health_check_eviction_time_in_min = 5

		# HTTPS only
		use_32_bit_worker = false
	}


	# Application settings (including Key Vault references)
	app_settings = merge({
		"WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false",
		"WEBSITE_ENABLE_SYNC_UPDATE_SITE"     = "true",
		"APPINSIGHTS_INSTRUMENTATIONKEY"      = azurerm_application_insights.main.instrumentation_key,
		"APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string,
		"KEY_VAULT_URL"                       = data.azurerm_key_vault.shared.vault_uri
	}, var.additional_app_settings,
		{ for k, v in var.key_vault_references : k => "@Microsoft.KeyVault(VaultName=${data.azurerm_key_vault.shared.name};SecretName=${v})" }
	)

	https_only = true

	logs {
		detailed_error_messages = true
		failed_request_tracing  = true

		application_logs {
			file_system_level = "Information"
		}

		http_logs {
			file_system {
				retention_in_days = 7
				retention_in_mb   = 35
			}
		}
	}

	tags = var.tags
}

# Sample Key Vault secrets
resource "azurerm_key_vault_secret" "sample_secrets" {
	for_each     = var.sample_secrets
	name         = each.key
	value        = each.value
	key_vault_id = data.azurerm_key_vault.shared.id

	tags = var.tags
}
