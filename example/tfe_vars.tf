variable "name_randomness" {
  type = number
  default = 62 # tfedev = 20 + 6 + 5 + 4 + 5 + 22 = 62
  description = "An arbitrary number that will be used for certain resources, you need to set this to any number between 0 and 255"

  # This affects the following elements:
  # - The second bit of the virtual network's CIDR, e.g. 10.<this_value>.0.0/24, this is why it must be between 0 and 255
  # - The hostname of the Azure Key Vault, as these must be unique worldwide and common ones like "tfe.vault.azure.net" are already taken
  # - The hostname of the Azure Blob endpoint, for the same reason
  # - The hostname of the Azure Files endpoint, for the same reason
  # - The hostname of the Postgres database endpoint, for the same reason

  # Variable validation is an experimental feature and is subject to change without notice
  validation {
    condition     = var.name_randomness >= 0 && var.name_randomness <= 255 && var.name_randomness % 1 == 0
    error_message = "The name_randomness value must be an integer between 0 and 255 inclusive."
  }
}

variable "key_vault_authorized_users" {
  type = list(string)
  default = [
    "a0b1c2d3-e4f5-a6b7-c8d9-e0f1a2b3c4d5", # some Azure AD user
    "c2d3a0b1-c8d9-e4f5-a6b7-b3c4d5e0f1a2", # another Azure AD user
    "d3a0c2b1-a6b7-c8d9-e4f5-b3e0f1c4d5a2", # some Azure AD group
  ]
  description = "A list of Azure AD objects (users/groups) in GUID format who will be allowed to interact with the Key Vault."
}

variable "key_vault_authorized_subnets" {
  type = list(string)
  default = [
    "1.2.3.4/32", # VPN site #1
    "2.3.4.5/32", # VPN site #2
    "3.4.5.6/24", # some IP range
  ]
  description = "A list of subnets that will be allowed to interact with the Key Vault. The TFE instance will be allowed automatically in addition to what you list here."
}

variable "storage_account_authorized_subnets" {
  type = list(string)
  default = [
    "1.2.3.4", # VPN site #1
    "2.3.4.5", # VPN site #2
    "2.3.4.6", # VPN site #2 alternate egress IP
    "3.4.5.0/24", # some IP range
  ]
  description = "A list of subnets that will be allowed to interact with the Storage Blob. The TFE instance will be allowed automatically in addition to what you list here."
  # If any subnet you include here is of size /30, /31 or /32,
  # you must omit the CIDR prefix and list single IPs without
  # the /32. This is due to an unfortunate limitation in the
  # Azure Storage Account API.
}

variable "tfe_authorized_subnets" {
  type = list(string)
  default = [
    "1.2.3.0/24", # Datacenter #1
    "2.3.4.0/23", # Datacenter #2
  ]
  description = "A list of subnets allowed to connect to TFE. This list will also be used for the IACT subnet list."
  # What is the IACT? 
  # https://www.terraform.io/docs/enterprise/install/automating-the-installer.html#iact_subnet_list
  # https://www.terraform.io/docs/enterprise/install/automating-initial-user.html
}

variable "tfe_admin_authorized_subnets" {
  type = list(string)
  default = [
    "1.2.3.4/32", # VPN site #1
    "2.3.4.5/32", # VPN site #2
    "2.3.4.6/32", # VPN site #2 alternate egress IP
    "3.4.5.0/24", # some IP range
  ]
  description = "A list of subnets allowed to connect to the TFE admin ports (SSH and 8800)."
}