resource "azurerm_storage_share" "snapshots" {
  name                 = "tfe-${var.names.environment}-snapshots"
  storage_account_name = var.storage_account_name
  quota                = 50

  metadata = var.tags
}