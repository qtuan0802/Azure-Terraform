# Shared Key Vault from root module
variable "key_vault_name" {
  description = "Name of the shared Key Vault to use for secrets and references"
  type        = string
}

variable "key_vault_resource_group" {
  description = "Resource group of the shared Key Vault"
  type        = string
}
# Resource Group and Azure context
variable "resource_group_name" {
  description = "Name of the resource group to deploy resources into"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "suffix" {
  description = "Random string for unique naming"
  type        = string
}

variable "deployment_object_id" {
  description = "Object ID for deployment access policy (current user/service principal)"
  type        = string
}

# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

# App Service Configuration
variable "app_service_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "B1"
  validation {
    condition = can(regex("^(F1|D1|B[1-3]|S[1-3]|P[1-3]V[2-3]|P[1-3]mv3|I[1-6]v2)$", var.app_service_sku))
    error_message = "Invalid App Service SKU."
  }
}

variable "java_version" {
  description = "Java version for the App Service"
  type        = string
  default     = "17-java17"
  validation {
    condition = contains(["8-jre8", "11-java11", "17-java17", "21-java21"], var.java_version)
    error_message = "Java version must be one of: 8-jre8, 11-java11, 17-java17, 21-java21."
  }
}

variable "health_check_path" {
  description = "Health check path for the application"
  type        = string
  default     = "/health"
}

# Key Vault Configuration
variable "key_vault_network_access" {
  description = "Default network access for Key Vault"
  type        = string
  default     = "Allow"
  validation {
    condition     = contains(["Allow", "Deny"], var.key_vault_network_access)
    error_message = "Key Vault network access must be Allow or Deny."
  }
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

# Application Configuration
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

variable "sample_secrets" {
  description = "Sample secrets to create in Key Vault"
  type        = map(string)
  default     = {}
}

# Tags
variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
}
