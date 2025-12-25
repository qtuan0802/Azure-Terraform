# Managed Identity module
module "managed_identity" {
  source              = "./modules/managed_identity"
  for_each            = toset(var.managed_identity_names)
  name                = each.value
  resource_group_name = azurerm_resource_group.fabric.name
  location            = azurerm_resource_group.fabric.location
  tags                = var.tags
}
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

# Resource Group for Fabric Resources
resource "azurerm_resource_group" "fabric" {
  name     = "rg-fabric-${var.environment}-${var.location_short}"
  location = var.location

  tags = var.tags
}

# Fabric Workspace - Reference existing workspace "DMLFabricWkspace"
# Workspace is managed manually in app.fabric.microsoft.com
locals {
  workspace_name = "DMLFabricWkspace" # Existing workspace name
  workspace_url  = "https://app.fabric.microsoft.com"
}

# Data Factory (if needed for data ingestion)
module "data_factory" {
  source = "./modules/data_factory"
  count  = var.enable_data_factory ? 1 : 0

  name                = "adf-fabric-${var.environment}-${var.location_short}"
  resource_group_name = azurerm_resource_group.fabric.name
  location            = azurerm_resource_group.fabric.location
  environment         = var.environment

  tags = var.tags
}

# Key Vault for secrets management
# module "key_vault" {
#   source = "./modules/key_vault"

#   name                = "kv-fabric-${var.environment}-${random_string.suffix.result}"
#   resource_group_name = azurerm_resource_group.fabric.name
#   location            = azurerm_resource_group.fabric.location
#   tenant_id           = data.azurerm_client_config.current.tenant_id

#   # Access policies
#   access_policies = var.key_vault_access_policies

#   tags = var.tags
# }

module "key_vault_sapsfbatch" {
  source = "./modules/key_vault"

  name                = "sapsfbatch-${var.environment}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.fabric.name
  location            = azurerm_resource_group.fabric.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # Access policies
  access_policies = var.key_vault_access_policies

  tags               = var.tags
  sapsfbatch_secrets = var.sapsfbatch_secrets
  expiration_hours   = var.expiration_hours
}

# Storage Account for OneLake integration
module "storage_account" {
  source = "./modules/storage"

  name                = "stfabric${var.environment}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.fabric.name
  location            = azurerm_resource_group.fabric.location

  # Configuration
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  # Security
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  # Network rules
  network_rules = var.storage_network_rules

  tags = var.tags
}

# Monitoring and Observability
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.enable_monitoring ? 1 : 0

  log_analytics_name        = "log-fabric-${var.environment}-${var.location_short}"
  application_insights_name = "appi-fabric-${var.environment}-${var.location_short}"
  action_group_name         = "ag-fabric-${var.environment}"
  action_group_short_name   = "fabric${var.environment}"

  resource_group_name = azurerm_resource_group.fabric.name
  location            = azurerm_resource_group.fabric.location
  environment         = var.environment

  # Notification settings
  email_receivers = var.email_receivers

  tags = var.tags
}

# Java Application Module
module "java_app" {
  source = "./modules/java_app"

  resource_group_name  = azurerm_resource_group.fabric.name
  location             = azurerm_resource_group.fabric.location
  tenant_id            = data.azurerm_client_config.current.tenant_id
  suffix               = random_string.suffix.result
  deployment_object_id = data.azurerm_client_config.current.object_id

  environment       = var.environment
  app_service_sku   = var.app_service_sku != null ? var.app_service_sku : "B1"
  java_version      = var.java_version != null ? var.java_version : "17-java17"
  health_check_path = var.health_check_path != null ? var.health_check_path : "/health"

  key_vault_network_access   = var.key_vault_network_access != null ? var.key_vault_network_access : "Allow"
  allowed_ip_addresses       = var.allowed_ip_addresses != null ? var.allowed_ip_addresses : []
  additional_key_vault_users = var.additional_key_vault_users != null ? var.additional_key_vault_users : []

  additional_app_settings = var.additional_app_settings != null ? var.additional_app_settings : {}
  key_vault_references    = var.key_vault_references != null ? var.key_vault_references : {}

  key_vault_name           = module.key_vault_sapsfbatch.key_vault_name
  key_vault_resource_group = azurerm_resource_group.fabric.name

  tags = var.tags

  # Managed Identity outputs (lấy identity đầu tiên trong danh sách)
  user_assigned_identity_id           = module.managed_identity[var.managed_identity_names[0]].id
  user_assigned_identity_principal_id = module.managed_identity[var.managed_identity_names[0]].principal_id
  user_assigned_identity_client_id    = module.managed_identity[var.managed_identity_names[0]].client_id

  enable_app_insights = var.enable_app_insights
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Current Azure configuration
data "azurerm_client_config" "current" {}
