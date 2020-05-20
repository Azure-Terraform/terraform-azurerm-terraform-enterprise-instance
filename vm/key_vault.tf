# Allows the TFE VM to perform the listed operations against this Key Vault instance
resource "azurerm_key_vault_access_policy" "secrets_for_vm" {
  key_vault_id = data.azurerm_key_vault.main.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = lookup(azurerm_linux_virtual_machine.tfe.identity[0], "principal_id")

  secret_permissions = ["get"]
}

resource "azurerm_key_vault_secret" "tfe_encryption_password" {
  name         = "tfe-${var.names.environment}-encryption-password"
  value        = random_password.enc_password.result
  key_vault_id = data.azurerm_key_vault.main.id

  tags = var.tags
}