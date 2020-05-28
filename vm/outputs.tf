output "public_ip" {
  value = azurerm_public_ip.vm.ip_address
}

output "fqdn" {
  value = var.tfe_hostname
}

output "application_security_group_name" {
  value = azurerm_application_security_group.main.name
}

output "application_security_group_id" {
  value = azurerm_application_security_group.main.id
}