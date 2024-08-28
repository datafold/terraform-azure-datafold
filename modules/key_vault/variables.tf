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

variable "identity_object_id" {
  type        = string
  description = "The principal ID of the identity"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the load balancer"
}