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
}

variable "location" {
  description = "The Azure location where the resources will be created"
  type        = string
  default     = ""
}

# ┏━╸╻  ╻┏━╸╻┏ ╻ ╻┏━┓╻ ╻┏━┓┏━╸   ┏┓ ┏━┓┏━╸╻┏ ╻ ╻┏━┓
# ┃  ┃  ┃┃  ┣┻┓┣━┫┃ ┃┃ ┃┗━┓┣╸    ┣┻┓┣━┫┃  ┣┻┓┃ ┃┣━┛
# ┗━╸┗━╸╹┗━╸╹ ╹╹ ╹┗━┛┗━┛┗━┛┗━╸   ┗━┛╹ ╹┗━╸╹ ╹┗━┛╹

variable "identity" {
  type = object({ id = string })
}

variable "vpc" {
  type = object({ id = string })
}

variable "private_endpoint_storage_subnet" {
  type = object({ id = string })
}

# ┏━┓┏━╸┏━┓┏━┓╻ ╻┏━┓┏━╸┏━╸   ┏┓╻┏━┓┏┳┓┏━╸   ┏━┓╻ ╻┏━╸┏━┓┏━┓╻╺┳┓┏━╸┏━┓
# ┣┳┛┣╸ ┗━┓┃ ┃┃ ┃┣┳┛┃  ┣╸    ┃┗┫┣━┫┃┃┃┣╸    ┃ ┃┃┏┛┣╸ ┣┳┛┣┳┛┃ ┃┃┣╸ ┗━┓
# ╹┗╸┗━╸┗━┛┗━┛┗━┛╹┗╸┗━╸┗━╸   ╹ ╹╹ ╹╹ ╹┗━╸   ┗━┛┗┛ ┗━╸╹┗╸╹┗╸╹╺┻┛┗━╸┗━┛

variable "storage_account_name_override" {
  description = "Override for the name used in resource.azurerm_storage_account.storage"
  type        = string
  default     = ""
}

variable "clickhouse_backup_container_name_override" {
  description = "Override for the name used in resource.azurerm_storage_container.clickhouse_backup"
  type        = string
  default     = ""
}

variable "storage_private_dns_zone_name_override" {
  description = "Override for the name used in resource.azurerm_private_dns_zone.storage_account_dns"
  type        = string
  default     = ""
}

variable "storage_private_endpoint_name_override" {
  description = "Override for the name used in resource.azurerm_private_endpoint.storage"
  type        = string
  default     = ""
}

variable "storage_dns_link_name_override" {
  description = "Override for the name used in resource.azurerm_private_dns_zone_virtual_network_link.storage_account_link"
  type        = string
  default     = ""
}