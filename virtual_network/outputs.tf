output "name" {
  value = azurerm_virtual_network.main.name
}

output "id" {
  value = azurerm_virtual_network.main.id
}

output "subnet_name" {
  value = azurerm_subnet.main.name
}

output "subnet_id" {
  value = azurerm_subnet.main.id
}

output "vault_subnet_name" {
  value = azurerm_subnet.vault.name
}

output "vault_subnet_id" {
  value = azurerm_subnet.vault.id
}

output "subnet_nsg_name" {
  value = azurerm_network_security_group.main.name
}

output "subnet_nsg_id" {
  value = azurerm_network_security_group.main.id
}