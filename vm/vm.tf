data "template_file" "application_settings_json" {
  template = "${file("${path.module}/template_application_settings.json.tpl")}"
  vars = {
    app_settings_path = local.tfe_application_settings_json_path
    azure_account_name = var.storage_account_name
    azure_container = var.storage_account_blob_container
    enc_password = random_password.enc_password.result
    hostname = var.tfe_hostname
    pg_netloc = var.pg_hostname
    pg_dbname = var.pg_dbname
    pg_simple_hostname = local.pg_simple_hostname # The DB hostname without the domain name, required with an @ for the username
    iact_subnet_list = join(",", var.authorized_subnets_main)
  }
}

data "template_file" "replicated_conf" {
  template = "${file("${path.module}/template_replicated.conf.tpl")}"
  vars = {
    app_settings_path = local.tfe_application_settings_json_path
    snapshots_path = local.tfe_snapshots_path
    hostname = var.tfe_hostname
    username = var.vm_username
    license_file_name = var.license_file_name
  }
}

resource "azurerm_linux_virtual_machine" "tfe" {
  name                = "tfe-mono-docker-${var.names.environment}-vm01"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.vm_username

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  admin_ssh_key {
    username = var.vm_username
    public_key = data.azurerm_key_vault_secret.vm_public_key.value
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type  = "Premium_LRS"
    caching               = "ReadWrite"
    disk_size_gb          = var.vm_os_disk_size
  }

  # Variables are listed in the order in which they appear in the custom data script
  custom_data = base64encode(templatefile("${path.module}/template_vm_custom_data.sh.tpl",{
    timezone = var.timezone
    app_settings_path = local.tfe_application_settings_json_path
    application_settings_json = data.template_file.application_settings_json.rendered
    replicated_conf = data.template_file.replicated_conf.rendered
    username = var.vm_username
    vanity_hostname_dns_zone_subscription_id = var.tfe_vanity_hostname_dns_zone_subscription_id
    azure_tenant_id = data.azurerm_client_config.current.tenant_id
    key_vault_name = data.azurerm_key_vault.main.name
    key_vault_uri = data.azurerm_key_vault.main.vault_uri
    azure_client_id = var.azure_client_id
    azure_client_secret = var.azure_client_secret
    hostname = var.tfe_hostname
    vanity_hostname = var.tfe_vanity_hostname
    replicated_console_password = var.replicated_console_password
    azure_account_name = var.storage_account_name
    pg_username = var.pg_admin_user
    pg_password = var.pg_admin_password
    azure_container = var.storage_account_blob_container
    license_file_name = var.license_file_name
    public_ip = azurerm_public_ip.vm.ip_address
    snapshots_path = local.tfe_snapshots_path
    azure_files_endpoint = var.storage_account_files_endpoint
    azure_files_share = azurerm_storage_share.snapshots.name
  }))

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}