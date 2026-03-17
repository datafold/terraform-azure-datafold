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

variable "backup_lifecycle_expiration_days" {
  type        = number
  default     = 7
  description = "Number of days after which temporal postgres backup objects will expire and be deleted."
}

# ┏━┓┏━╸┏━┓┏━┓╻ ╻┏━┓┏━╸┏━╸   ┏┓╻┏━┓┏┳┓┏━╸   ┏━┓╻ ╻┏━╸┏━┓┏━┓╻╺┳┓┏━╸┏━┓
# ┣┳┛┣╸ ┗━┓┃ ┃┃ ┃┣┳┛┃  ┣╸    ┃┗┫┣━┫┃┃┃┣╸    ┃ ┃┃┏┛┣╸ ┣┳┛┣┳┛┃ ┃┃┣╸ ┗━┓
# ╹┗╸┗━╸┗━┛┗━┛┗━┛╹┗╸┗━╸┗━╸   ╹ ╹╹ ╹╹ ╹┗━╸   ┗━┛┗┛ ┗━╸╹┗╸╹┗╸╹╺┻┛┗━╸┗━┛

variable "storage_account_name_override" {
  description = "Override for the name used in resource.azurerm_storage_account.temporal_backup"
  type        = string
  default     = ""
}

variable "container_name_override" {
  description = "Override for the name used in resource.azurerm_storage_container.temporal_backup"
  type        = string
  default     = ""
}
