variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "authorized_users" {
  type = set(string)
  description = "A set of Azure AD objects (users/groups) in GUID format who will be allowed to interact with the Key Vault."
}

variable "authorized_subnets" {
  type = list(string)
  description = "A list of subnets that will be allowed to interact with the Key Vault. The TFE instance will be allowed automatically in addition to what you list here."
}

variable "tfe_subnet" {
  type = string
  description = "The ID of the subnet where the TFE instance lives."
}

variable "name_randomness" {
  type = number
  description = "An arbitrary number that is used to 'randomize' the hostname of the Key Vault, you need to set this to any number between 0 and 255"
}

variable "names" {
  type = map
}

variable "tags" {
  type = map
}