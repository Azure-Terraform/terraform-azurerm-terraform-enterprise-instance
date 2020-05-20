resource "azurerm_role_definition" "tfe" {
  name        = "${azurerm_linux_virtual_machine.tfe.name}-role"
  scope       = azurerm_linux_virtual_machine.tfe.id
  description = "Allows TFE to access Key Vault and Blob Container"

  assignable_scopes = [
    azurerm_linux_virtual_machine.tfe.id,
  ]

  permissions {
    data_actions  = [
      "Microsoft.KeyVault/vaults/secrets/getSecret/action",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
    ]
  }
}

resource "azurerm_role_assignment" "tfe" {
  scope              = azurerm_linux_virtual_machine.tfe.id
  role_definition_id = azurerm_role_definition.tfe.id
  principal_id       = lookup(azurerm_linux_virtual_machine.tfe.identity[0], "principal_id")
}