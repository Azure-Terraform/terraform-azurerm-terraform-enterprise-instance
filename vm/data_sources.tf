data "azurerm_client_config" "current" {}
data "github_ip_ranges" "main" {}

data "azurerm_key_vault" "main" {
  name                = var.key_vault
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_secret" "vm_public_key" {
  name         = var.vm_public_key
  key_vault_id = data.azurerm_key_vault.main.id
}

resource "random_password" "enc_password" {
  length = 35
}

locals {
  github_hooks_subnets = data.github_ip_ranges.main.hooks
  # The local path on the TFE VM where to mount the Azure Files CIFS volume and store application snapshots
  tfe_snapshots_path = "/var/lib/tfe_snapshots"
  # The path to which to write TFE application settings (for automated setup)
  tfe_application_settings_json_path = "/etc/tfe_application_settings.json"
  hostname_elements = split(".", var.tfe_hostname)
  simple_hostname = element(slice(local.hostname_elements, 0, 1), 0)
  hostname_domain = join(".", slice(local.hostname_elements, 1, length(local.hostname_elements)))
  pg_simple_hostname = element(slice(split(".", var.pg_hostname), 0, 1), 0)
}

data "azurerm_dns_zone" "main" {
  name                = local.hostname_domain
  resource_group_name = var.dns_zone_resource_group
}