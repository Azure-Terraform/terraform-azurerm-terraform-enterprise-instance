resource "azurerm_storage_account" "main" {
  name                     = "tfe${var.names.environment}${var.name_randomness}"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action              = "Deny"
    bypass                      = ["AzureServices"]
    ip_rules                    = local.ip_whitelist
    virtual_network_subnet_ids  = list(var.tfe_subnet)
  }

  lifecycle {
    ignore_changes = [
      queue_properties,
      resource_group_name,
      location,
      account_tier,
      account_kind,
      is_hns_enabled
    ]
  }

  tags = var.tags
}

resource "azurerm_key_vault_secret" "storage_account_key1" {
  name         = "${azurerm_storage_account.main.name}-storage-account-key1"
  value        = azurerm_storage_account.main.primary_access_key
  key_vault_id = var.key_vault_id

  tags = var.tags
}

resource "azurerm_key_vault_secret" "storage_account_key2" {
  name         = "${azurerm_storage_account.main.name}-storage-account-key2"
  value        = azurerm_storage_account.main.secondary_access_key
  key_vault_id = var.key_vault_id

  tags = var.tags
}

resource "azurerm_storage_container" "main" {
  name                 = "tfe-${var.names.environment}"
  storage_account_name = azurerm_storage_account.main.name
  
  metadata = var.tags
}