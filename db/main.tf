resource "azurerm_postgresql_server" "main" {
  name                = "tfe-${var.names.environment}${var.name_randomness}"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name  = var.sku_name
  version   = "11"

  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"

  public_network_access_enabled = true

  storage_mb                    = var.storage_mb
  auto_grow_enabled             = true
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = true

  administrator_login          = data.azurerm_key_vault_secret.db_user.value
  administrator_login_password = data.azurerm_key_vault_secret.db_password.value

  tags = var.tags
}

resource "azurerm_postgresql_database" "main" {
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.main.name

  name      = "tfe_${var.names.environment}"
  charset   = "UTF8"
  collation = "en-US"
}

resource "azurerm_postgresql_virtual_network_rule" "main" {
  name                                 = "${azurerm_postgresql_server.main.name}-vnet-rule"
  resource_group_name                  = var.resource_group_name
  server_name                          = azurerm_postgresql_server.main.name
  subnet_id                            = var.tfe_subnet
  ignore_missing_vnet_service_endpoint = false
}