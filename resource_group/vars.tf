variable "location" {
  type = string
  description = "The Azure region where to create the resource group"
}

variable "names" {
  type = map
  description = "See https://github.com/LexisNexis-Terraform/terraform-azurerm-metadata"
}

variable "tags" {
  type = map(string)
  description = "A map of tags to assign to each resource created by this module"
  # See https://github.com/LexisNexis-Terraform/terraform-azurerm-metadata
}