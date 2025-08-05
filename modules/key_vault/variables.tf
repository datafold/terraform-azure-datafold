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


# ╻┏ ┏━╸╻ ╻   ╻ ╻┏━┓╻ ╻╻  ╺┳╸
# ┣┻┓┣╸ ┗┳┛   ┃┏┛┣━┫┃ ┃┃   ┃
# ╹ ╹┗━╸ ╹    ┗┛ ╹ ╹┗━┛┗━╸ ╹

variable "identity" {
  type = object({ id = string, principal_id = string })
}

variable "domain_name" {
  type        = string
  description = "The domain name for the load balancer"
}

# ┏━╸┏━╸┏━┓╺┳╸
# ┃  ┣╸ ┣┳┛ ┃
# ┗━╸┗━╸╹┗╸ ╹

variable "acme_provider" {
  type        = string
  description = "The name of the provider for the DNS challenge"
}

variable "acme_config" {
  type        = any
  description = "The configuration for the provider of the DNS challenge"
}

# ┏━┓┏━╸┏━┓┏━┓╻ ╻┏━┓┏━╸┏━╸   ┏┓╻┏━┓┏┳┓┏━╸   ┏━┓╻ ╻┏━╸┏━┓┏━┓╻╺┳┓┏━╸┏━┓
# ┣┳┛┣╸ ┗━┓┃ ┃┃ ┃┣┳┛┃  ┣╸    ┃┗┫┣━┫┃┃┃┣╸    ┃ ┃┃┏┛┣╸ ┣┳┛┣┳┛┃ ┃┃┣╸ ┗━┓
# ╹┗╸┗━╸┗━┛┗━┛┗━┛╹┗╸┗━╸┗━╸   ╹ ╹╹ ╹╹ ╹┗━╸   ┗━┛┗┛ ┗━╸╹┗╸╹┗╸╹╺┻┛┗━╸┗━┛

variable "key_vault_name_override" {
  description = "Override for the name used in resource.azurerm_key_vault.default"
  type        = string
  default     = ""
}

variable "etcd_key_name_override" {
  description = "Override for the name used in resource.azurerm_key_vault_key.etcd"
  type        = string
  default     = ""
}

variable "ssl_certificate_name_override" {
  description = "Override for the name used in resource.azurerm_key_vault_certificate.ssl"
  type        = string
  default     = ""
}
