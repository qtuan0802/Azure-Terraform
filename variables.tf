# Managed Identity
variable "managed_identity_names" {
  description = "Danh sách tên các user-assigned managed identity cần tạo cho các service khác nhau. Định nghĩa qua tfvars cho từng môi trường."
  type        = list(string)
  default     = []
}
variable "enable_app_insights" {
  description = "Enable Application Insights for java_app module"
  type        = bool
  default     = true
}
# Environment Configuration
variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
  validation {
    condition     = can(regex("^(dev|uat|prod)$", var.environment))
    error_message = "Environment must be dev, uat, or prod."
  }
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "location_short" {
  description = "Short form of Azure region for naming"
  type        = string
  default     = "eus"
}

variable "workspace_suffix" {
  description = "Suffix for workspace naming"
  type        = string
  default     = "main"
}

# Fabric Configuration
variable "fabric_capacity_id" {
  description = "Microsoft Fabric capacity ID"
  type        = string
}

variable "enable_data_factory" {
  description = "Enable Azure Data Factory for data ingestion"
  type        = bool
  default     = true
}

variable "use_existing_workspace" {
  description = "Whether to reference an existing fabric workspace instead of creating new one"
  type        = bool
  default     = true  # Since we have existing "DMLFabricWkspace"
}

# RBAC Configuration
variable "admin_users" {
  description = "List of admin user principal names"
  type        = list(string)
  default     = []
}

variable "admin_groups" {
  description = "List of admin group object IDs"
  type        = list(string)
  default     = []
}

variable "contributor_users" {
  description = "List of contributor user principal names"
  type        = list(string)
  default     = []
}

variable "contributor_groups" {
  description = "List of contributor group object IDs"
  type        = list(string)
  default     = []
}

variable "viewer_users" {
  description = "List of viewer user principal names"
  type        = list(string)
  default     = []
}

variable "viewer_groups" {
  description = "List of viewer group object IDs"
  type        = list(string)
  default     = []
}

# Storage Configuration
variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "storage_network_rules" {
  description = "Storage account network rules"
  type = object({
    default_action             = string
    bypass                     = list(string)
    ip_rules                  = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
    ip_rules                  = []
    virtual_network_subnet_ids = []
  }
}

# Key Vault Configuration
variable "key_vault_access_policies" {
  description = "Key Vault access policies"
  type = list(object({
    object_id          = string
    key_permissions    = list(string)
    secret_permissions = list(string)
    certificate_permissions = list(string)
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default = {
    Environment = ""
    Project     = "Microsoft-Fabric"
    ManagedBy   = "Terraform"
  }
}

# Java App variables for module integration
variable "app_service_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "B1"
}

variable "java_version" {
  description = "Java version for the App Service"
  type        = string
  default     = "17-java17"
}

variable "health_check_path" {
  description = "Health check path for the application"
  type        = string
  default     = "/health"
}

variable "key_vault_network_access" {
  description = "Default network access for Key Vault"
  type        = string
  default     = "Allow"
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "additional_key_vault_users" {
  description = "Additional users/service principals for Key Vault access"
  type = list(object({
    object_id               = string
    secret_permissions      = list(string)
    key_permissions         = list(string)
    certificate_permissions = list(string)
  }))
  default = []
}

variable "additional_app_settings" {
  description = "Additional application settings for the App Service"
  type        = map(string)
  default     = {}
}

variable "key_vault_references" {
  description = "Key Vault secret references for app settings"
  type        = map(string)
  default     = {}
}

variable "expiration_hours" {
  description = "Number of hours after which the Key Vault secrets will expire"
  type        = number
  default     = null
}

variable "sample_secrets" {
  description = "Sample secrets to create in Key Vault"
  type        = map(string)
  default     = {}
}

# Sapsfbatch Key Vault Secrets (required + optional, see key_vault.txt)
variable "sapsfbatch_secrets" {
  description = "Secrets for sapsfbatch Key Vault (required + optional, see key_vault.txt)"
  type        = map(string)
  default     = {}
}