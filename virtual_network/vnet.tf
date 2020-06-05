resource "azurerm_virtual_network" "main" {
  name                = "tfe-${var.names.environment}-${var.names.location}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location

  address_space       = ["10.${var.name_randomness}.0.0${var.cidr_prefix}"]

  tags = var.tags
}

resource "azurerm_subnet" "main" {
  name                 = "tfe-${var.names.environment}-${var.names.location}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes     = [cidrsubnet(azurerm_virtual_network.main.address_space[0], 1, 0)]

  enforce_private_link_endpoint_network_policies = true
  enforce_private_link_service_network_policies  = false

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.Storage",
  ]
}

resource "azurerm_subnet" "vault" {
  name                 = "tfe-vault-${var.names.environment}-${var.names.location}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes     = [cidrsubnet(azurerm_virtual_network.main.address_space[0], 1, 1)]

  enforce_private_link_endpoint_network_policies = true
  enforce_private_link_service_network_policies  = false

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.Storage",
  ]
}