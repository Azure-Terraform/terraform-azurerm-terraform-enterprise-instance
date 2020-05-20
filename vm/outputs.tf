output "public_ip" {
  value = azurerm_public_ip.vm.ip_address
}

output "fqdn" {
  value = var.tfe_hostname
}