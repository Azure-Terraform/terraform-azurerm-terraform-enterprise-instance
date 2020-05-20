variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_randomness" {
  type = number
  description = "An arbitrary number that is used to 'randomize' the hostname of the Storage Account, you need to set this to any number between 0 and 255"
}

variable "authorized_subnets" {
  type = list(string)
  description = "A list of subnets that will be allowed to interact with the Storage Account. The TFE instance will be allowed automatically in addition to what you list here."
}

variable "tfe_subnet" {
  type = string
  description = "The ID of the subnet where the TFE instance lives."
}

variable "key_vault_id" {
  type = string
  description = "The ID of an Azure Key Vault where to record the storage account keys"
}

variable "names" {
  type = map
}

variable "tags" {
  type = map
}