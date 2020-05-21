module "tfe_postgres_db" {
  source = "github.com/Azure-Terraform/terraform-azurerm-terraform-enterprise-instance//db?ref=v0.1.0"

  resource_group_name   = module.tfe_rg.name
  location              = module.tfe_rg.location

  name_randomness       = var.name_randomness

  sku_name              = "GP_Gen5_4"
  storage_mb            = 51200
  backup_retention_days = 14

  tfe_subnet            = module.tfe_vnet.subnet_id

  key_vault_id          = module.tfe_key_vault.id

  # DO NOT PROVIDE PLAIN TEXT CREDENTIALS HERE, IT'S NOT SECURE AND WILL NOT WORK ANYWAY
  # READ THE README TO LEARN HOW THIS WORKS
  admin_user            = "..."
  admin_password        = "..."

  names = module.tfe_metadata.names
  tags  = module.tfe_metadata.tags
}