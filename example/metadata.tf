module "tfe_metadata" {
  source = "github.com/Azure-Terraform/terraform-azurerm-metadata?ref=v1.0.0"

  business_unit       = "..."
  cost_center         = "..."
  environment         = "..."
  location            = "..."
  market              = "..."
  product_group       = "..."
  product_name        = "..."
  project             = "..."
  resource_group_type = "..."
  subscription_id     = var.subscription_id
  subscription_type   = "..."

  additional_tags = {
    project_path = "https://github.com/org/repo"
  }
}