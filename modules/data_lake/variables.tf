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

# ┏━┓╺┳┓╻  ┏━┓
# ┣━┫ ┃┃┃  ┗━┓
# ╹ ╹╺┻┛┗━╸┗━┛

variable "identity" {
  type = object({ id = string, principal_id = string })
}

variable "vpc" {
  type = object({ id = string })
}

variable "private_endpoint_adls_subnet" {
  type = object({ id = string })
}

# ┏━┓┏━╸┏━┓┏━┓╻ ╻┏━┓┏━╸┏━╸   ┏┓╻┏━┓┏┳┓┏━╸   ┏━┓╻ ╻┏━╸┏━┓┏━┓╻╺┳┓┏━╸┏━┓
# ┣┳┛┣╸ ┗━┓┃ ┃┃ ┃┣┳┛┃  ┣╸    ┃┗┫┣━┫┃┃┃┣╸    ┃ ┃┃┏┛┣╸ ┣┳┛┣┳┛┃ ┃┃┣╸ ┗━┓
# ╹┗╸┗━╸┗━┛┗━┛┗━┛╹┗╸┗━╸┗━╸   ╹ ╹╹ ╹╹ ╹┗━╸   ┗━┛┗┛ ┗━╸╹┗╸╹┗╸╹╺┻┛┗━╸┗━┛

variable "adls_storage_account_name_override" {
  description = "Override for the name used in resource.azurerm_storage_account.adls"
  type        = string
  default     = ""
}

variable "adls_filesystem_name_override" {
  description = "Override for the name used in resource.azurerm_storage_data_lake_gen2_filesystem.adls"
  type        = string
  default     = ""
}

variable "adls_private_dns_zone_name_override" {
  description = "Override for the name used in resource.azurerm_private_dns_zone.adls"
  type        = string
  default     = ""
}

variable "adls_dns_link_name_override" {
  description = "Override for the name used in resource.azurerm_private_dns_zone_virtual_network_link.adls"
  type        = string
  default     = ""
}

variable "adls_private_endpoint_name_override" {
  description = "Override for the name used in resource.azurerm_private_endpoint.adls"
  type        = string
  default     = ""
}