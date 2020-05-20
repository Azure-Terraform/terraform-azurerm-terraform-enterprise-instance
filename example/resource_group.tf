module "tfe_rg" {
  source = "https://github.com/LexisNexis-Terraform/terraform-azurerm-terraform-enterprise-instance.git//resource_group?ref=v0.1.0"

  location = "East US"

  names = module.tfe_metadata.names
  tags  = module.tfe_metadata.tags
}