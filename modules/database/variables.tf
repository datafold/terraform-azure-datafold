# ┏━╸┏━┓┏┳┓┏┳┓┏━┓┏┓╻   ╻ ╻┏━┓┏━┓╻┏━┓┏┓ ╻  ┏━╸┏━┓
# ┃  ┃ ┃┃┃┃┃┃┃┃ ┃┃┗┫   ┃┏┛┣━┫┣┳┛┃┣━┫┣┻┓┃  ┣╸ ┗━┓
# ┗━╸┗━┛╹ ╹╹ ╹┗━┛╹ ╹   ┗┛ ╹ ╹╹┗╸╹╹ ╹┗━┛┗━╸┗━╸┗━┛

variable "deployment_name" {
  description = "The name of the deployment"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the resources will be created"
  type        = string
  default     = ""
}

variable "location" {
  description = "The Azure location where the resources will be created"
  type        = string
  default     = ""
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Map of tags for resource"
}

#  ╺┳┓┏━┓╺┳╸┏━┓┏┓ ┏━┓┏━┓┏━╸
#   ┃┃┣━┫ ┃ ┣━┫┣┻┓┣━┫┗━┓┣╸
#  ╺┻┛╹ ╹ ╹ ╹ ╹┗━┛╹ ╹┗━┛┗━╸

variable "database_username" {
  type        = string
  default     = "datafold"
  description = "ProgreSQL username"
}

variable "database_name" {
  type        = string
  default     = "datafold"
  description = "Postgres database name"
}

variable "database_subnet" {
  type = object({
    id = string
  })
}

variable "database_sku" {
  type        = string
  default     = "GP_Standard_D2s_v3"
  description = "PostgreSQL SKU"
}

variable "database_backup_retention_days" {
  type        = number
  default     = 7
  description = "PostgreSQL backup retention days"
}

variable "database_storage_mb" {
  type        = number
  default     = 32768
  description = "PostgreSQL storage in MB. One of a predetermined set of values, see: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server#storage_mb"
}

variable "private_dns_zone_id" {
  type        = string
  description = "The ID of the private DNS zone"
}

variable "postgresql_major_version" {
  type        = string
  description = "PostgreSQL major version"
}

# ┏━┓┏━╸┏━┓┏━┓╻ ╻┏━┓┏━╸┏━╸   ┏┓╻┏━┓┏┳┓┏━╸   ┏━┓╻ ╻┏━╸┏━┓┏━┓╻╺┳┓┏━╸┏━┓
# ┣┳┛┣╸ ┗━┓┃ ┃┃ ┃┣┳┛┃  ┣╸    ┃┗┫┣━┫┃┃┃┣╸    ┃ ┃┃┏┛┣╸ ┣┳┛┣┳┛┃ ┃┃┣╸ ┗━┓
# ╹┗╸┗━╸┗━┛┗━┛┗━┛╹┗╸┗━╸┗━╸   ╹ ╹╹ ╹╹ ╹┗━╸   ┗━┛┗┛ ┗━╸╹┗╸╹┗╸╹╺┻┛┗━╸┗━┛

variable "postgresql_server_name_override" {
  description = "Override for the name used in resource.azurerm_postgresql_flexible_server.main"
  type        = string
  default     = ""
}

variable "postgresql_database_name_override" {
  description = "Override for the name used in resource.azurerm_postgresql_flexible_server_database.main"
  type        = string
  default     = ""
}
