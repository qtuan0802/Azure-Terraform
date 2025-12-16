# Azure Data Factory
resource "azurerm_data_factory" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  
  # Identity
  identity {
    type = "SystemAssigned"
  }
  
  # GitHub integration (if provided)
  dynamic "github_configuration" {
    for_each = var.github_configuration != null ? [var.github_configuration] : []
    content {
      account_name    = github_configuration.value.account_name
      branch_name     = github_configuration.value.branch_name
      repository_name = github_configuration.value.repository_name
      root_folder     = github_configuration.value.root_folder
      git_url         = github_configuration.value.git_url
    }
  }
  
  # VSTS configuration (if provided)
  dynamic "vsts_configuration" {
    for_each = var.vsts_configuration != null ? [var.vsts_configuration] : []
    content {
      account_name    = vsts_configuration.value.account_name
      branch_name     = vsts_configuration.value.branch_name
      project_name    = vsts_configuration.value.project_name
      repository_name = vsts_configuration.value.repository_name
      root_folder     = vsts_configuration.value.root_folder
      tenant_id       = vsts_configuration.value.tenant_id
    }
  }
  
  # Public network access
  public_network_enabled = var.public_network_enabled
  
  tags = var.tags
}

# Linked Service for Azure Storage
resource "azurerm_data_factory_linked_service_azure_blob_storage" "storage" {
  count               = var.storage_account_name != null ? 1 : 0
  name                = "ls-storage-${var.environment}"
  data_factory_id     = azurerm_data_factory.main.id
  connection_string   = "DefaultEndpointsProtocol=https;AccountName=${var.storage_account_name};AccountKey=${var.storage_account_key};EndpointSuffix=core.windows.net"
}

# Linked Service for Key Vault
resource "azurerm_data_factory_linked_service_key_vault" "key_vault" {
  count           = var.key_vault_id != null ? 1 : 0
  name            = "ls-keyvault-${var.environment}"
  data_factory_id = azurerm_data_factory.main.id
  key_vault_id    = var.key_vault_id
}

# Integration Runtime (Self-hosted if required)
resource "azurerm_data_factory_integration_runtime_self_hosted" "main" {
  count           = var.enable_self_hosted_ir ? 1 : 0
  name            = "ir-selfhosted-${var.environment}"
  data_factory_id = azurerm_data_factory.main.id
  description     = "Self-hosted Integration Runtime for ${var.environment}"
}

# Managed Private Endpoint for Fabric (if enabled)
resource "azurerm_data_factory_managed_private_endpoint" "fabric" {
  count              = var.enable_managed_private_endpoint ? 1 : 0
  name               = "pe-fabric-${var.environment}"
  data_factory_id    = azurerm_data_factory.main.id
  target_resource_id = var.fabric_workspace_id
  subresource_name   = "dataflows"
}

# Data Factory Pipeline for Fabric ingestion
resource "azurerm_data_factory_pipeline" "fabric_ingestion" {
  count           = var.create_sample_pipeline ? 1 : 0
  name            = "pipeline-fabric-ingestion"
  data_factory_id = azurerm_data_factory.main.id
  
  activities_json = jsonencode([
    {
      name = "CopyToFabric"
      type = "Copy"
      typeProperties = {
        source = {
          type = "BlobSource"
        }
        sink = {
          type = "PowerBISink"
        }
      }
      inputs = [
        {
          referenceName = "ds-source-blob"
          type = "DatasetReference"
        }
      ]
      outputs = [
        {
          referenceName = "ds-fabric-dataset"
          type = "DatasetReference"
        }
      ]
    }
  ])
}

# Trigger for the pipeline (if enabled)
resource "azurerm_data_factory_trigger_schedule" "fabric_ingestion" {
  count           = var.create_sample_pipeline && var.enable_pipeline_trigger ? 1 : 0
  name            = "trigger-fabric-ingestion"
  data_factory_id = azurerm_data_factory.main.id
  pipeline_name   = azurerm_data_factory_pipeline.fabric_ingestion[0].name
  
  frequency = var.pipeline_trigger_frequency
  interval  = var.pipeline_trigger_interval
  
  start_time = var.pipeline_trigger_start_time
}