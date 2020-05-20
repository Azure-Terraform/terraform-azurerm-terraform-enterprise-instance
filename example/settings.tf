terraform {
  required_version = "~> 0.12.20"

  # backend "azurerm" {
  #   resource_group_name  = "..."
  #   storage_account_name = "..."
  #   container_name       = "..."
  #   key                  = "terraform.tfstate"
  # }

  experiments = [variable_validation]
}

variable "subscription_id" {
  default = "a0b1c2d3-e4f5-a6b7-c8d9-e0f1a2b3c4d5"
}

provider "azurerm" {
  version = "~> 2.7"
  subscription_id = var.subscription_id

  features {}
}

provider "tls" {
  version = "~> 2.1"
}

provider "github" {
  version = "~> 2.7"

  individual = true
}

provider "random" {
  version = "~> 2.2"
}

provider "template" {
  version = "~> 2.1"
}