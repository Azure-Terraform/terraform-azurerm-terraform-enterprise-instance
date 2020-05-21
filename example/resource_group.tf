module "tfe_rg" {
  source = "github.com/Azure-Terraform/terraform-azurerm-terraform-enterprise-instance//resource_group?ref=v0.1.0"

  location = "East US"

  names = module.tfe_metadata.names
  tags  = module.tfe_metadata.tags
}