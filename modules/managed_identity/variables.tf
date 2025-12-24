variable "name" {
  description = "Tên của managed identity"
  type        = string
}

variable "resource_group_name" {
  description = "Tên resource group"
  type        = string
}

variable "location" {
  description = "Vị trí Azure region"
  type        = string
}

variable "tags" {
  description = "Tags cho resource"
  type        = map(string)
  default     = {}
}
