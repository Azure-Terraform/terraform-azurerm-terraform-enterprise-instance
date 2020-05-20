variable "resource_group_name" {
  type = string
  description = "The name of the resource group in which you wish to place the DB instance"
}

variable "location" {
  type = string
  description = "The Azure region where the database instance should live"
}

variable "name_randomness" {
  type = number
  description = "An arbitrary number that is used to 'randomize' the hostname of the Storage Account, you need to set this to any number between 0 and 255"
}

variable "tfe_subnet" {
  type = string
  description = "The ID of the subnet where the TFE instance lives."
}

variable "sku_name" {
  type = string
  description = "The SKU that determines how many vCPUs and gigabytes of memory are available to your database instance"

  # Variable validation is an experimental feature and is subject to change without notice
  validation {
    condition     = can(regex("^GP_", var.sku_name)) || can(regex("^MO_", var.sku_name))
    error_message = "You must use General Purpose or Memory-Optimized SKUs due to Basic SKUs not supporting certain features we require (such as Private Endpoint)."
  }
}

variable "storage_mb" {
  type = number
  default = 5120
  description = "The size (in megabytes) of your instance; must be divisible by 1024"

  # Variable validation is an experimental feature and is subject to change without notice
  validation {
    condition     = var.storage_mb >= 5120 && var.storage_mb <= 4194304 && var.storage_mb % 1024 == 0
    error_message = "The storage_mb value must be between 5120 and 4194304, and must be divisible by 1024."
  }
}

variable "backup_retention_days" {
  type = number
  default = 7
  description = "The number of days for which to retain backup"

  # Variable validation is an experimental feature and is subject to change without notice
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "The backup_retention_days variable must be set to a value between 7 and 35."
  }
}

variable "key_vault_id" {
  type = string
  description = ""
}

variable "admin_user" {
  type = string
  description = "The administrator username to connect to the database"
}

variable "admin_password" {
  type = string
  description = "The administrator password to connect to the database"
}

variable "names" {
  type = map
}

variable "tags" {
  type = map(string)
  description = "A map of tags to assign to each resource created by this module"
}