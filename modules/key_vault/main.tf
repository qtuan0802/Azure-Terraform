# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  
  sku_name = var.sku_name
  
  # Access policies
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  
  # Soft delete and purge protection
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = true  # Required by Azure policy
  
  # Enable RBAC authorization
  enable_rbac_authorization = true  # Required by Azure policy
  
  # Network access
  public_network_access_enabled = var.public_network_access_enabled
  
  # Network ACLs
  network_acls {
    default_action = var.network_acls.default_action
    bypass         = var.network_acls.bypass
    ip_rules       = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }
  
  tags = var.tags
}

# Access policies for specified users/groups
resource "azurerm_key_vault_access_policy" "access_policies" {
  count        = length(var.access_policies)
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = var.access_policies[count.index].object_id
  
  key_permissions    = var.access_policies[count.index].key_permissions
  secret_permissions = var.access_policies[count.index].secret_permissions
  certificate_permissions = var.access_policies[count.index].certificate_permissions
}

# Default access policy for current user/service principal
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  
  key_permissions = [
    "Create", "Delete", "Get", "List", "Purge", "Recover", "Update"
  ]
  
  secret_permissions = [
    "Delete", "Get", "List", "Purge", "Recover", "Set"
  ]
  
  certificate_permissions = [
    "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import",
    "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge",
    "Recover", "SetIssuers", "Update"
  ]
}

# Sample secrets for Fabric configuration
resource "azurerm_key_vault_secret" "fabric_secrets" {
  for_each     = var.fabric_secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [
    azurerm_key_vault_access_policy.current_user
  ]
}

# Private endpoint (if enabled)
resource "azurerm_private_endpoint" "key_vault" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  
  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
  
  private_dns_zone_group {
    name                 = "pdz-group-${var.name}"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
  
  tags = var.tags
}