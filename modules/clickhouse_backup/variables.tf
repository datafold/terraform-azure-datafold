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