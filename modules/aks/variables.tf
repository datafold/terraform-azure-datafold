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

variable "resource_group_id" {
  description = "The ID of the resource group where the resources will be created"
  type        = string
}

variable "location" {
  description = "The Azure location where the resources will be created"
  type        = string
  default     = ""
}

# ╻┏ ╻ ╻┏┓ ┏━╸┏━┓┏┓╻┏━╸╺┳╸┏━╸┏━┓
# ┣┻┓┃ ┃┣┻┓┣╸ ┣┳┛┃┗┫┣╸  ┃ ┣╸ ┗━┓
# ╹ ╹┗━┛┗━┛┗━╸╹┗╸╹ ╹┗━╸ ╹ ┗━╸┗━┛

variable "etcd_key_vault_key_id" {
  description = "The ID of the key (stored in Key Vault) used to encryypt etcd's persistent storage."
  nullable    = false
  type        = string
}

variable "identity" {
  type = object({ id = string })
}

variable "gateway" {
  type = object({ id = string })
}

variable "aks_subnet" {
  type = object({ id = string })
}

variable "app_gw_subnet" {
  type = object({ id = string })
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Map of tags for resource"
}

variable "node_pool_name" {
  description = "The name of the node pool"
  type        = string
  default     = "default"
}

variable "node_pool_vm_size" {
  type = string
}

variable "node_pool_node_count" {
  type = number
}

variable "sku_tier" {
  type    = string
  default = "Free"
}

variable "max_pods" {
  type        = number
  description = "Maximum number of pods per node"
  default     = 50
}

variable "service_cidr" {
  type        = string
  description = "The CIDR block for the services subnet"
}

variable "dns_service_ip" {
  type        = string
  description = "The IP address for the DNS service"
}