# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "email_receivers" {
  description = "List of email receivers for alerts"
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "sms_receivers" {
  description = "List of SMS receivers for alerts"
  type = list(object({
    name         = string
    country_code = string
    phone_number = string
  }))
  default = []
}

variable "webhook_receivers" {
  description = "List of webhook receivers for alerts"
  type = list(object({
    name                    = string
    service_uri            = string
    use_common_alert_schema = bool
  }))
  default = []
}

variable "storage_capacity_threshold_gb" {
  description = "Storage capacity threshold in GB for alerts"
  type        = number
  default     = 1000
}

variable "datafactory_failed_runs_threshold" {
  description = "Data Factory failed runs threshold for alerts"
  type        = number
  default     = 5
}

variable "create_monitoring_dashboard" {
  description = "Create Azure monitoring dashboard"
  type        = bool
  default     = true
}