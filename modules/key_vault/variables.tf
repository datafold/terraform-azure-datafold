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
