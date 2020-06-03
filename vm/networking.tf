resource "azurerm_public_ip" "vm" {
  name                = "tfe-${var.names.environment}-publicip01"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = var.tags
}

resource "azurerm_dns_a_record" "main" {
  name                = local.simple_hostname
  zone_name           = data.azurerm_dns_zone.main.name
  resource_group_name = var.dns_zone_resource_group
  ttl                 = 300

  records = [azurerm_public_ip.vm.ip_address]

  tags = var.tags
}

resource "azurerm_network_interface" "vm" {
  name                = "tfe-mono-docker-${var.names.environment}01-${var.tfe_subnet_name}-interface01"
  resource_group_name = var.resource_group_name
  location            = var.location

  enable_accelerated_networking = true

  ip_configuration {
    name                          = "tfe-mono-docker-${var.names.environment}01-${var.tfe_subnet_name}-interface01"
    subnet_id                     = var.tfe_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = var.tags
}

resource "azurerm_application_security_group" "main" {
  name = "tfe-${var.names.environment}-app-security-group"

  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

resource "azurerm_network_interface_application_security_group_association" "main" {
  network_interface_id          = azurerm_network_interface.vm.id
  application_security_group_id = azurerm_application_security_group.main.id
}

resource "azurerm_application_security_group" "admin" {
  name = "tfeadmin-${var.names.environment}-app-security-group"

  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

resource "azurerm_network_interface_application_security_group_association" "admin" {
  network_interface_id          = azurerm_network_interface.vm.id
  application_security_group_id = azurerm_application_security_group.admin.id
}

#
# INBOUND RULES
#

# Ensure TFE is allowed to connect to itself
resource "azurerm_network_security_rule" "inbound-tfe-self" {
  name  = "inbound-tfe-self"

  resource_group_name = var.resource_group_name
  network_security_group_name = var.tfe_subnet_nsg

  priority                                    = 480
  direction                                   = "Inbound"
  access                                      = "Allow"
  protocol                                    = "Tcp"
  source_address_prefixes                     = ["${azurerm_public_ip.vm.ip_address}/32"]
  source_port_range                           = "*"
  destination_application_security_group_ids  = [azurerm_application_security_group.main.id]
  destination_port_ranges                     = ["80","443"]
}

# List of IP addresses allowed to connect to TFE instance
resource "azurerm_network_security_rule" "inbound-tfe-direct" {
  name  = "inbound-tfe-direct"

  resource_group_name = var.resource_group_name
  network_security_group_name = var.tfe_subnet_nsg

  priority                                    = 490
  direction                                   = "Inbound"
  access                                      = "Allow"
  protocol                                    = "Tcp"
  source_address_prefixes                     = var.authorized_subnets_main
  source_port_range                           = "*"
  destination_application_security_group_ids  = [azurerm_application_security_group.main.id]
  destination_port_ranges                     = ["80","443"]
}

# List of IP addresses allowed to connect to TFE admin ports (SSH and admin GUI on port 8800)
resource "azurerm_network_security_rule" "inbound-tfe-administration-ports" {
  name  = "inbound-tfe-administration-ports"

  resource_group_name = var.resource_group_name
  network_security_group_name = var.tfe_subnet_nsg

  priority                                    = 500
  direction                                   = "Inbound"
  access                                      = "Allow"
  protocol                                    = "Tcp"
  source_address_prefixes                     = var.authorized_subnets_admin
  source_port_range                           = "*"
  destination_application_security_group_ids  = [azurerm_application_security_group.admin.id]
  destination_port_ranges                     = ["22","8800"]
}

# List of IP addresses obtained from https://api.github.com/meta under "hooks" category
# These are IP addresses used by GitHub to send webhooks to remote hosts such as our TFE instance
resource "azurerm_network_security_rule" "inbound-github-hooks" {
  name  = "inbound-github-hooks"

  resource_group_name = var.resource_group_name
  network_security_group_name = var.tfe_subnet_nsg

  priority                                    = 510
  direction                                   = "Inbound"
  access                                      = "Allow"
  protocol                                    = "Tcp"
  source_address_prefixes                     = local.github_hooks_subnets
  source_port_range                           = "*"
  destination_application_security_group_ids  = [azurerm_application_security_group.main.id]
  destination_port_range                      = "443"
}