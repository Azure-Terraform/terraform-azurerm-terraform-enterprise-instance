module "tfe_vm" {
  source = "github.com/Azure-Terraform/terraform-azurerm-terraform-enterprise-instance//vm?ref=v0.1.0"

  resource_group_name                           = module.tfe_rg.name
  location                                      = module.tfe_rg.location

  tfe_hostname                                  = "tfe.environment.subdomain.domain.com"
  dns_zone_resource_group                       = "some-resource-group"

  tfe_vanity_hostname                           = "tfe.domain.com"
  tfe_vanity_hostname_dns_zone_subscription_id  = "e0f1c4d5-a6b7-e4f5-c8d9-a0b1a2b3c2d3"

  vm_size                                       = "Standard_D4as_v4" # this is the minimum size
  vm_os_disk_size                               = 128 # gigabytes

  tfe_subnet_name                               = module.tfe_vnet.subnet_name
  tfe_subnet_id                                 = module.tfe_vnet.subnet_id
  tfe_subnet_nsg                                = module.tfe_vnet.subnet_nsg_name

  authorized_subnets_main                       = var.tfe_authorized_subnets
  authorized_subnets_admin                      = var.tfe_admin_authorized_subnets

  key_vault                                     = module.tfe_key_vault.name

  storage_account_name                          = module.tfe_storage_blob.name
  storage_account_blob_container                = module.tfe_storage_blob.container_name
  storage_account_files_endpoint                = module.tfe_storage_blob.files_endpoint

  pg_hostname                                   = "${module.tfe_postgres_db.fqdn}:5432"
  pg_dbname                                     = module.tfe_postgres_db.tfe_db

  # Secrets
  # DO NOT PROVIDE PLAIN TEXT CREDENTIALS HERE, IT'S NOT SECURE AND WILL NOT WORK ANYWAY
  # READ THE README TO LEARN HOW THIS WORKS
  pg_admin_user                                 = "..."
  pg_admin_password                             = "..."
  replicated_console_password                   = "..."
  vm_public_key                                 = "..."
  azure_client_id                               = "..."
  azure_client_secret                           = "..."

  license_file_name                             = "yourcompany.rli"

  names = module.tfe_metadata.names
  tags  = module.tfe_metadata.tags
}