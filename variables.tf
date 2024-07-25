# ┏━╸┏━┓┏┳┓┏┳┓┏━┓┏┓╻   ╻ ╻┏━┓┏━┓╻┏━┓┏┓ ╻  ┏━╸┏━┓
# ┃  ┃ ┃┃┃┃┃┃┃┃ ┃┃┗┫   ┃┏┛┣━┫┣┳┛┃┣━┫┣┻┓┃  ┣╸ ┗━┓
# ┗━╸┗━┛╹ ╹╹ ╹┗━┛╹ ╹   ┗┛ ╹ ╹╹┗╸╹╹ ╹┗━┛┗━╸┗━╸┗━┛

variable "deployment_name" {
  description = "The name of the deployment"
  type        = string
}

variable "create_resource_group" {
  type        = bool
  default     = true
  description = "Flag to toggle resource group creation"
}

variable "resource_group_name" {
  description = "The name of the resource group where the resources will be created"
  type        = string
  default     = ""
}

variable "resource_group_tags" {
  description = "The tags to apply to the resource group"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "The environment for the resources"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "The Azure location where the resources will be created"
  type        = string
  default     = ""
}

# ┏┓╻┏━╸╺┳╸╻ ╻┏━┓┏━┓╻┏
# ┃┗┫┣╸  ┃ ┃╻┃┃ ┃┣┳┛┣┻┓
# ╹ ╹┗━╸ ╹ ┗┻┛┗━┛╹┗╸╹ ╹

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
  default     = ""
}

# ╻  ┏━┓┏━┓╺┳┓   ┏┓ ┏━┓╻  ┏━┓┏┓╻┏━╸┏━╸┏━┓
# ┃  ┃ ┃┣━┫ ┃┃   ┣┻┓┣━┫┃  ┣━┫┃┗┫┃  ┣╸ ┣┳┛
# ┗━╸┗━┛╹ ╹╺┻┛   ┗━┛╹ ╹┗━╸╹ ╹╹ ╹┗━╸┗━╸╹┗╸

variable "gw_private_ip_address" {
  description = "The private IP address of the gateway. Should be within the gateway subnet CIDR range."
  type        = string
  default     = "10.0.9.10"
}

# ╺┳┓┏━┓╺┳╸┏━┓┏┓ ┏━┓┏━┓┏━╸
#  ┃┃┣━┫ ┃ ┣━┫┣┻┓┣━┫┗━┓┣╸
# ╺┻┛╹ ╹ ╹ ╹ ╹┗━┛╹ ╹┗━┛┗━╸

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

variable "postgresql_major_version" {
  type        = string
  default     = "15"
  description = "PostgreSQL major version"
}

# ╻┏ ╻ ╻┏┓ ┏━╸┏━┓┏┓╻┏━╸╺┳╸┏━╸┏━┓
# ┣┻┓┃ ┃┣┻┓┣╸ ┣┳┛┃┗┫┣╸  ┃ ┣╸ ┗━┓
# ╹ ╹┗━┛┗━┛┗━╸╹┗╸╹ ╹┗━╸ ╹ ┗━╸┗━┛

variable "max_pods" {
  description = "The maximum number of pods that can run on a node"
  type        = number
  default     = 50
}

variable "node_pool_node_count" {
  description = "The number of nodes in the pool"
  type        = number
  default     = 1
}

variable "node_pool_vm_size" {
  description = "The size of the VMs in the pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "node_pool_name" {
  description = "The name of the node pool"
  type        = string
  default     = "default"
}

variable "aks_sku_tier" {
  description = "The SKU tier for the cluster"
  type        = string
  default     = "Free"
}

variable "aks_service_cidr" {
  description = "The CIDR block for the Kubernetes services"
  type        = string
  default     = "172.16.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "The IP address for the Kubernetes DNS service"
  type        = string
  default     = "172.16.0.10"
}
