data "azurerm_key_vault_secret" "db_user" {
  name         = var.admin_user
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "db_password" {
  name         = var.admin_password
  key_vault_id = var.key_vault_id
}