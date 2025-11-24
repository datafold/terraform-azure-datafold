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

variable "use_existing_database" {
  description = "Whether to use an existing PostgreSQL database instead of creating a new one"
  type        = bool
  default     = false
}

variable "existing_resource_group_name" {
  description = "The name of the resource group containing the existing PostgreSQL database"
  type        = string
  default     = ""

  validation {
    condition = var.use_existing_database == false || (var.use_existing_database == true && var.existing_resource_group_name != "")
    error_message = "existing_resource_group_name must be provided when use_existing_database is true."
  }
}

variable "existing_postgresql_server_name" {
  description = "The name of the existing PostgreSQL flexible server"
  type        = string
  default     = ""

  validation {
    condition = var.use_existing_database == false || (var.use_existing_database == true && var.existing_postgresql_server_name != "")
    error_message = "existing_postgresql_server_name must be provided when use_existing_database is true."
  }
}

variable "existing_postgresql_database_name" {
  description = "The name of the existing PostgreSQL database"
  type        = string
  default     = ""

  validation {
    condition = var.use_existing_database == false || (var.use_existing_database == true && var.existing_postgresql_database_name != "")
    error_message = "existing_postgresql_database_name must be provided when use_existing_database is true."
  }
}

variable "existing_vnet_resource_group_name" {
  description = "The name of the resource group containing the existing VNet with the PostgreSQL database"
  type        = string
  default     = ""

  validation {
    condition = var.use_existing_database == false || (var.use_existing_database == true && var.existing_vnet_resource_group_name != "")
    error_message = "existing_vnet_resource_group_name must be provided when use_existing_database is true."
  }
}

variable "existing_vnet_name" {
  description = "The name of the existing VNet containing the PostgreSQL database"
  type        = string
  default     = ""

  validation {
    condition = var.use_existing_database == false || (var.use_existing_database == true && var.existing_vnet_name != "")
    error_message = "existing_vnet_name must be provided when use_existing_database is true."
  }
}

variable "existing_database_subnet_name" {
  description = "The name of the subnet in the existing VNet where the PostgreSQL database is located"
  type        = string
  default     = ""

  validation {
    condition = var.use_existing_database == false || (var.use_existing_database == true && var.existing_database_subnet_name != "")
    error_message = "existing_database_subnet_name must be provided when use_existing_database is true."
  }
}

variable "existing_private_dns_zone_name" {
  description = "The name of the existing private DNS zone for PostgreSQL (usually 'privatelink.postgres.database.azure.com')"
  type        = string
  default     = "privatelink.postgres.database.azure.com"
}

variable "our_vnet_id" {
  description = "The ID of our VNet that needs to peer with the existing VNet"
  type        = string
  default     = ""
}

variable "our_vnet_name" {
  description = "The name of our VNet for peering configuration"
  type        = string
  default     = ""
}

variable "our_private_endpoint_subnet_id" {
  description = "The ID of our subnet where the private endpoint should be created"
  type        = string
  default     = ""
}

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
  default = null
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
  default     = null
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

variable "postgresql_private_endpoint_name_override" {
  description = "Override for the name used in resource.azurerm_private_endpoint.postgresql"
  type        = string
  default     = ""
}

# Note: DNS zone name override removed since we use existing DNS zone

variable "postgresql_vnet_peering_name_prefix_override" {
  description = "Override for the name prefix used in VNet peering resources"
  type        = string
  default     = ""
}
