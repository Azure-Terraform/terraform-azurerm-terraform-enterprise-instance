variable "resource_group_name" {
  type = string
  description = "The name of the resource group in which you wish to place the DB instance"
}

variable "location" {
  type = string
  description = "The Azure region where the database instance should live"
}

variable "vm_size" {
  type = string
  description = "The size (CPU/RAM) of the VM"
}

variable "vm_os_disk_size" {
  type = string
  description = "The size of the VM's root disk -- should be integral powers of 2, e.g. 32, 64, 128, 256, etc."
  # The reason for the integral powers of 2 is Azure storage is based on predefined SKUs and you pay the price of the next largest tier even if provisioning less than it
  # e.g. if you want a 100 GB disk, that's between 64 and 128, so you will pay the rate of a 128 GB disk even though you only get 100 GB, so you might as well request
  # a 128 GB disk as it's the same price as for 100 GB.
}

variable "vm_username" {
  type = string
  default = "ubuntu"
  description = "The admin username for the VM"
}

variable "tfe_subnet_name" {
  type = string
  description = "The name of the subnet where the TFE instance lives."
}

variable "tfe_subnet_id" {
  type = string
  description = "The ID of the subnet where the TFE instance lives."
}

variable "tfe_subnet_nsg" {
  type = string
  description = "The name of the network security group attached to the subnet where the TFE instance lives."
}

variable "tfe_hostname" {
  type = string
  description = "The FQDN of the TFE server"
}

variable "dns_zone_resource_group" {
  type = string
  description = "The resource group containing the Azure DNS zone where the DNS record for TFE will reside. This may or may not be the same resource group that you're using for TFE itself."
}

variable "authorized_subnets_main" {
  type = list(string)
  description = "A list of subnets that will be allowed to connect to TFE."
}

variable "authorized_subnets_admin" {
  type = list(string)
  description = "A list of subnets that will be allowed to connect to TFE's admin ports (22 and 8800)."
}

variable "replicated_console_password" {
  type = string
  description = "The NAME of the Key Vault secret containing the password to access TFE Admin Console"
  # TFE has an admin console on port 8800 that is separate from the main application. It's not tied to the
  # auth scheme you chose for the application itself. This password is used to access said admin console.
}

variable "key_vault" {
  type = string
  description = "The name of the Azure Key Vault instance where the secrets reside"
}

variable "pg_hostname" {
  type = string
  description = "The fully-qualified domain name and port (hostname.domain.com:port) of the Postgres endpoint"
}

variable "pg_dbname" {
  type = string
  description = "The name of the Postgres database"
}

variable "storage_account_name" {
  type = string
  description = "The name of the Azure Storage Account where the Blob Container resides"
}

variable "storage_account_blob_container" {
  type = string
  description = "The name of the Azure Storage Container where TFE will place objects. This is also the place from which we retrieve the Hashicorp license file during setup."
}

variable "storage_account_files_endpoint" {
  type = string
  description = "The hostname of the Azure Files endpoint in the Storage Account, without https:// or trailing /, e.g. tfe.file.core.windows.net"
}

variable "license_file_name" {
  type = string
  description = "The name of the license file sent to us by HashiCorp -- you must make sure this variable matches the name of the file that you upload manually to the Azure blob container"
}

variable "timezone" {
  type = string
  default = "America/New_York"
  description = "This will set the timezone for the TFE VM"
}

variable "pg_admin_user" {
  type = string
  description = "The NAME of the Key Vault secret containing the Postgres DB username that TFE will use to connect to the DB"
}

variable "pg_admin_password" {
  type = string
  description = "The NAME of the Key Vault secret containing the Postgres DB password that TFE will use to connect to the DB"
}

variable "vm_public_key" {
  type = string
  description = "The NAME of the Key Vault secret containing a public key to add to the TFE VM's authorized_keys file"
}

variable "azure_client_id" {
  type = string
  description = "The NAME of the Key Vault secret containing the Azure Service Principal ID to use when requesting the SSL certificate"
}

variable "azure_client_secret" {
  type = string
  description = "The NAME of the Key Vault secret containing the Azure Service Principal secret to use when requesting the SSL certificate"
}

variable "names" {
  type = map
}

variable "tags" {
  type = map(string)
  description = "A map of tags to assign to each resource created by this module"
}