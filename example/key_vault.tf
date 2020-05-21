module "tfe_key_vault" {
  source = "github.com/Azure-Terraform/terraform-azurerm-terraform-enterprise-instance//key_vault?ref=v0.1.0"

  resource_group_name = module.tfe_rg.name
  location            = module.tfe_rg.location

  name_randomness     = var.name_randomness

  tfe_subnet          = module.tfe_vnet.subnet_id

  authorized_users    = var.key_vault_authorized_users
  authorized_subnets  = var.key_vault_authorized_subnets

  names = module.tfe_metadata.names
  tags  = module.tfe_metadata.tags
}