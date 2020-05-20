module "tfe_vnet" {
  source = "https://github.com/LexisNexis-Terraform/terraform-azurerm-terraform-enterprise-instance.git//virtual_network?ref=v0.1.0"

  resource_group_name = module.tfe_rg.name
  location            = module.tfe_rg.location

  name_randomness     = var.name_randomness

  names = module.tfe_metadata.names
  tags  = module.tfe_metadata.tags
}