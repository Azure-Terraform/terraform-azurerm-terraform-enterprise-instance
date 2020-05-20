data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

locals {
  ip_whitelist = var.authorized_subnets
}