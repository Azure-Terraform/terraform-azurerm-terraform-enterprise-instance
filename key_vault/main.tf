resource "azurerm_key_vault" "main" {
  name                        = "tfe${var.names.environment}${var.name_randomness}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = false
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    default_action              = "Deny"
    bypass                      = "AzureServices"
    ip_rules                    = local.ip_whitelist
    virtual_network_subnet_ids  = list(var.tfe_subnet, var.vault_subnet)
  }

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "authorized_users" {
  for_each  = var.authorized_users

  key_vault_id = azurerm_key_vault.main.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = each.key

  secret_permissions      = ["get","list","set","delete","recover","purge"]
  certificate_permissions = ["get","list","create","delete","recover","backup","restore","purge","update"]
  key_permissions         = ["get", "create", "delete", "list", "restore", "recover", "unwrapkey", "wrapkey", "purge", "encrypt", "decrypt", "sign", "verify"]
}