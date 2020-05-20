resource "azurerm_resource_group" "rg" {
  name     = "shared-tfe-${var.names.environment}"
  location = var.location
  tags     = var.tags
}