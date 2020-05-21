module "tfe_vnet" {
  source = "github.com/Azure-Terraform/terraform-azurerm-terraform-enterprise-instance//virtual_network?ref=v0.1.0"

  resource_group_name = module.tfe_rg.name
  location            = module.tfe_rg.location

  name_randomness     = var.name_randomness

  names = module.tfe_metadata.names
  tags  = module.tfe_metadata.tags
}