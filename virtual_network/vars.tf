variable "resource_group_name" {
  type = string
  description = "The name of the resource group in which to place the virtual network and associated resources"
}

variable "location" {
  type = string
  description = "The Azure region where to create the virtual network (should match the resource group's region)"
}

variable "cidr_prefix" {
  type = string
  default = "/24"
  description = "The CIDR prefix of the virtual network"
}

variable "name_randomness" {
  type = number
  description = "An arbitrary number that is used to 'randomize' the hostname of the Key Vault, you need to set this to any number between 0 and 255"
}

variable "names" {
  type = map
  description = "See https://github.com/Azure-Terraform/terraform-azurerm-metadata"
}

variable "tags" {
  type = map(string)
  description = "A map of tags to assign to each resource created by this module"
  # See https://github.com/Azure-Terraform/terraform-azurerm-metadata
}