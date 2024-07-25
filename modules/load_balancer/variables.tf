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

# ╻  ┏━┓┏━┓╺┳┓   ┏┓ ┏━┓╻  ┏━┓┏┓╻┏━╸┏━╸┏━┓
# ┃  ┃ ┃┣━┫ ┃┃   ┣┻┓┣━┫┃  ┣━┫┃┗┫┃  ┣╸ ┣┳┛
# ┗━╸┗━┛╹ ╹╺┻┛   ┗━┛╹ ╹┗━╸╹ ╹╹ ╹┗━╸┗━╸╹┗╸

variable "app_gw_subnet" {
  type = object({ id = string })
}

variable "private_ip_address" {
  type        = string
  description = "The private IP address of the load balancer"
}