output "name" {
  value = azurerm_postgresql_server.main.name
}

output "id" {
  value = azurerm_postgresql_server.main.id
}

output "fqdn" {
  value = azurerm_postgresql_server.main.fqdn
}

output "tfe_db" {
  value = azurerm_postgresql_database.main.name
}