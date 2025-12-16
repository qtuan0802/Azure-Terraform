variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

# Log Analytics Workspace
variable "log_analytics_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "log_analytics_sku" {
  description = "SKU of the Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "Retention must be between 30 and 730 days."
  }
}

# Application Insights
variable "application_insights_name" {
  description = "Name of the Application Insights instance"
  type        = string
}

# Action Group
variable "action_group_name" {
  description = "Name of the action group"
  type        = string
}

variable "action_group_short_name" {
  description = "Short name of the action group"
  type        = string
  validation {
    condition     = length(var.action_group_short_name) <= 12
    error_message = "Action group short name must be 12 characters or less."
  }
}

# Notification Receivers
variable "email_receivers" {
  description = "List of email receivers"
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "sms_receivers" {
  description = "List of SMS receivers"
  type = list(object({
    name         = string
    country_code = string
    phone_number = string
  }))
  default = []
}

variable "webhook_receivers" {
  description = "List of webhook receivers"
  type = list(object({
    name                    = string
    service_uri            = string
    use_common_alert_schema = bool
  }))
  default = []
}

# Resource IDs for monitoring
variable "storage_account_id" {
  description = "Storage account resource ID"
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Key Vault resource ID"
  type        = string
  default     = null
}

variable "data_factory_id" {
  description = "Data Factory resource ID"
  type        = string
  default     = null
}

# Alert Thresholds
variable "storage_capacity_threshold_gb" {
  description = "Storage capacity threshold in GB"
  type        = number
  default     = 1000
}

variable "datafactory_failed_runs_threshold" {
  description = "Data Factory failed runs threshold"
  type        = number
  default     = 5
}

# Dashboard
variable "create_dashboard" {
  description = "Create Azure Dashboard"
  type        = bool
  default     = true
}

# Diagnostic Settings
variable "storage_diagnostic_logs" {
  description = "Storage account diagnostic log categories"
  type        = list(string)
  default     = ["StorageRead", "StorageWrite", "StorageDelete"]
}

variable "keyvault_diagnostic_logs" {
  description = "Key Vault diagnostic log categories"
  type        = list(string)
  default     = ["AuditEvent", "AzurePolicyEvaluationDetails"]
}

variable "datafactory_diagnostic_logs" {
  description = "Data Factory diagnostic log categories"
  type        = list(string)
  default     = ["ActivityRuns", "PipelineRuns", "TriggerRuns"]
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}