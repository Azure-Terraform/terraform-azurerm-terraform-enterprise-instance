resource "azurerm_network_security_group" "main" {
  name                = "tfe-${var.names.environment}-${var.names.location}-subnet-security-group"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge(var.tags, {subnet_type = "iaas-public"})
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_network_security_rule" "deny_all_inbound" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name

  name                        = "DenyAllInbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "deny_all_outbound" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name

  name                        = "DenyAllOutbound"
  priority                    = 4096
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# Allow outbound connections to required Azure services
# AzureActiveDirectory
# AzureBackup
# AzureKeyVault
# Sql
# Storage

resource "azurerm_network_security_rule" "outbound-azure-active-directory" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name

  name = "outbound-azure-active-directory"

  priority                    = 460
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  destination_address_prefix  = "AzureActiveDirectory"
  destination_port_range      = "*"
}

resource "azurerm_network_security_rule" "outbound-azure-backup" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name

  name = "outbound-azure-backup"

  priority                    = 465
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  destination_address_prefix  = "AzureBackup"
  destination_port_range      = "*"
}

resource "azurerm_network_security_rule" "outbound-azure-key-vault" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name

  name = "outbound-azure-key-vault"

  priority                    = 470
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  destination_address_prefix  = "AzureKeyVault"
  destination_port_range      = "*"
}

resource "azurerm_network_security_rule" "outbound-azure-db-service" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name

  name = "outbound-azure-db-service"

  priority                    = 475
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  destination_address_prefix  = "Sql"
  destination_port_range      = "*"
}

resource "azurerm_network_security_rule" "outbound-azure-storage-account" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name

  name = "outbound-azure-storage-account"

  priority                    = 480
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  destination_address_prefix  = "Storage"
  destination_port_range      = "*"
}

# Allow outbound DNS UDP to the Internet
resource "azurerm_network_security_rule" "outbound-dns-udp-to-internet" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name

  name = "outbound-dns-udp-to-internet"

  priority                    = 489
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  destination_address_prefix  = "Internet"
  destination_port_range      = "53"
}

# Allow outbound DNS TCP to the Internet
resource "azurerm_network_security_rule" "outbound-dns-tcp-to-internet" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name

  name = "outbound-dns-tcp-to-internet"

  priority                    = 490
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  destination_address_prefix  = "Internet"
  destination_port_range      = "53"
}

# Allow outbound HTTP/HTTPS to the Internet
resource "azurerm_network_security_rule" "outbound-http-to-internet" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name

  name = "outbound-http-to-internet"

  priority                    = 500
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  destination_address_prefix  = "Internet"
  destination_port_ranges     = ["80","443"]
}

# Allow outbound SMTP to the Internet
resource "azurerm_network_security_rule" "outbound-smtp-to-internet" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name

  name = "outbound-smtp-to-internet"

  priority                    = 510
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "VirtualNetwork"
  source_port_range           = "*"
  destination_address_prefix  = "Internet"
  destination_port_range      = "587"
}