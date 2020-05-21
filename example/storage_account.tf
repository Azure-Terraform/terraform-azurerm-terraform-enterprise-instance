module "tfe_storage_blob" {
  source = "github.com/Azure-Terraform/terraform-azurerm-terraform-enterprise-instance//storage_blob?ref=v0.1.0"

  resource_group_name = module.tfe_rg.name
  location            = module.tfe_rg.location

  name_randomness     = var.name_randomness

  tfe_subnet          = module.tfe_vnet.subnet_id

  authorized_subnets  = var.storage_account_authorized_subnets

  key_vault_id        = module.tfe_key_vault.id

  names = module.tfe_metadata.names
  tags  = module.tfe_metadata.tags
}