output "name" {
  value = azurerm_storage_account.main.name
}

output "id" {
  value = azurerm_storage_account.main.id
}

output "container_name" {
  value = azurerm_storage_container.main.name
}

output "container_id" {
  value = azurerm_storage_container.main.id
}

output "files_endpoint" {
  value = trimsuffix(trimprefix(azurerm_storage_account.main.primary_file_endpoint, "https://"), "/")
}