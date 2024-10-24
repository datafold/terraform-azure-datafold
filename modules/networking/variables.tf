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

variable "create_resource_group" {
  description = "Flag to toggle resource group creation"
  type        = bool
  default     = true
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Map of tags for resource"
}

# ╻ ╻┏━┓┏━╸
# ┃┏┛┣━┛┃
# ┗┛ ╹  ┗━╸

variable "vpc_cidrs" {
  description = "The address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "virtual_network_tags" {
  description = "The tags to apply to the virtual network"
  type        = map(string)
  default     = {}
}

variable "aks_subnet_cidrs" {
  description = "The CIDR block for the AKS subnet"
  type        = list(string)
  default     = ["10.0.0.0/22"]
}

variable "private_endpoint_storage_subnet_cidrs" {
  description = "The CIDR block for the private endpoint storage subnet"
  type        = list(string)
  default     = ["10.0.4.0/24"]
}

variable "azure_bastion_subnet_cidrs" {
  description = "The CIDR block for the Azure Bastion subnet"
  type        = list(string)
  default     = ["10.0.5.0/24"]
}

variable "vm_bastion_subnet_cidrs" {
  description = "The CIDR block for the VM Bastion subnet"
  type        = list(string)
  default     = ["10.0.6.0/24"]
}

variable "database_subnet_cidrs" {
  description = "The CIDR block for the database subnet"
  type        = list(string)
  default     = ["10.0.7.0/24"]
}

variable "app_subnet_cidrs" {
  description = "The CIDR block for the app subnet"
  type        = list(string)
  default     = ["10.0.8.0/24"]
}

variable "app_gw_subnet_cidrs" {
  description = "The CIDR block for the app gateway subnet"
  type        = list(string)
  default     = ["10.0.9.0/24"]
}

variable "jumpbox_custom_data" {
  description = "Custom data for the jumpbox. Can be used to e.g. pass on ~/.ssh/authorized_keys with a cloud-init script."
  type        = string
  default     = null
}