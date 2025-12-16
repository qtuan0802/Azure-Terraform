variable "name" {
  description = "Name of the Data Factory"
  type        = string
}

variable "location" {
  description = "Location of the Data Factory"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "public_network_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

# Git Configuration
variable "github_configuration" {
  description = "GitHub configuration for Data Factory"
  type = object({
    account_name    = string
    branch_name     = string
    repository_name = string
    root_folder     = string
    git_url         = string
  })
  default = null
}

variable "vsts_configuration" {
  description = "Azure DevOps configuration for Data Factory"
  type = object({
    account_name    = string
    branch_name     = string
    project_name    = string
    repository_name = string
    root_folder     = string
    tenant_id       = string
  })
  default = null
}

# Linked Services
variable "storage_account_name" {
  description = "Storage account name for linked service"
  type        = string
  default     = null
}

variable "storage_account_key" {
  description = "Storage account key for linked service"
  type        = string
  default     = null
  sensitive   = true
}

variable "key_vault_id" {
  description = "Key Vault ID for linked service"
  type        = string
  default     = null
}

variable "fabric_workspace_id" {
  description = "Fabric workspace ID"
  type        = string
  default     = null
}

# Integration Runtime
variable "enable_self_hosted_ir" {
  description = "Enable self-hosted integration runtime"
  type        = bool
  default     = false
}

variable "enable_managed_private_endpoint" {
  description = "Enable managed private endpoint for Fabric"
  type        = bool
  default     = false
}

# Pipeline Configuration
variable "create_sample_pipeline" {
  description = "Create sample pipeline for Fabric ingestion"
  type        = bool
  default     = false
}

variable "enable_pipeline_trigger" {
  description = "Enable pipeline trigger"
  type        = bool
  default     = false
}

variable "pipeline_trigger_frequency" {
  description = "Pipeline trigger frequency"
  type        = string
  default     = "Hour"
}

variable "pipeline_trigger_interval" {
  description = "Pipeline trigger interval"
  type        = number
  default     = 1
}

variable "pipeline_trigger_start_time" {
  description = "Pipeline trigger start time"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}