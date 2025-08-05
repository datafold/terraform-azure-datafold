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
}

variable "virtual_network_tags" {
  description = "The tags to apply to the virtual network"
  type        = map(string)
  default     = {}
}

variable "aks_subnet_cidrs" {
  description = "The CIDR block for the AKS subnet"
  type        = list(string)
}

variable "private_endpoint_storage_subnet_cidrs" {
  description = "The CIDR block for the private endpoint storage subnet"
  type        = list(string)
}

variable "private_endpoint_adls_subnet_cidrs" {
  description = "The CIDR block for the private endpoint storage subnet"
  type        = list(string)
  default     = []
}

variable "azure_bastion_subnet_cidrs" {
  description = "The CIDR block for the Azure Bastion subnet"
  type        = list(string)
}

variable "vm_bastion_subnet_cidrs" {
  description = "The CIDR block for the VM Bastion subnet"
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "The CIDR block for the database subnet"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "The CIDR block for the app subnet"
  type        = list(string)
}

variable "app_gw_subnet_cidrs" {
  description = "The CIDR block for the app gateway subnet"
  type        = list(string)
}

variable "jumpbox_custom_data" {
  description = "Custom data for the jumpbox. Can be used to e.g. pass on ~/.ssh/authorized_keys with a cloud-init script."
  type        = string
  default     = null
}

variable "lb_is_public" {
  description = "Flag that determines if LB is public"
  type        = bool
}

variable "k8s_public_access_cidrs" {
  type        = list(string)
  description = "List of CIDRs that are allowed to connect to the EKS control plane"
}

variable "private_cluster_enabled" {
  type        = bool
  description = "Flag to enable private cluster"
  default     = true
}

# ┏━┓┏━╸┏━┓┏━┓╻ ╻┏━┓┏━╸┏━╸   ┏┓╻┏━┓┏┳┓┏━╸   ┏━┓╻ ╻┏━╸┏━┓┏━┓╻╺┳┓┏━╸┏━┓
# ┣┳┛┣╸ ┗━┓┃ ┃┃ ┃┣┳┛┃  ┣╸    ┃┗┫┣━┫┃┃┃┣╸    ┃ ┃┃┏┛┣╸ ┣┳┛┣┳┛┃ ┃┃┣╸ ┗━┓
# ╹┗╸┗━╸┗━┛┗━┛┗━┛╹┗╸┗━╸┗━╸   ╹ ╹╹ ╹╹ ╹┗━╸   ┗━┛┗┛ ┗━╸╹┗╸╹┗╸╹╺┻┛┗━╸┗━┛

variable "virtual_network_name_override" {
  description = "Override for the name used in resource.azurerm_virtual_network.vnet"
  type        = string
  default     = ""
}

variable "aks_subnet_name_override" {
  description = "Override for the name used in resource.azurerm_subnet.aks_subnet"
  type        = string
  default     = ""
}

variable "private_endpoint_storage_subnet_name_override" {
  description = "Override for the name used in resource.azurerm_subnet.private_endpoint_storage"
  type        = string
  default     = ""
}

variable "private_endpoint_adls_subnet_name_override" {
  description = "Override for the name used in resource.azurerm_subnet.private_endpoint_adls"
  type        = string
  default     = ""
}

variable "azure_bastion_subnet_name_override" {
  description = "Override for the name used in resource.azurerm_subnet.azure_bastion_subnet"
  type        = string
  default     = ""
}

variable "vm_bastion_subnet_name_override" {
  description = "Override for the name used in resource.azurerm_subnet.vm_bastion_subnet"
  type        = string
  default     = ""
}

variable "database_subnet_name_override" {
  description = "Override for the name used in resource.azurerm_subnet.database_subnet"
  type        = string
  default     = ""
}

variable "app_subnet_name_override" {
  description = "Override for the name used in resource.azurerm_subnet.app_subnet"
  type        = string
  default     = ""
}

variable "app_gw_subnet_name_override" {
  description = "Override for the name used in resource.azurerm_subnet.app_gw_subnet"
  type        = string
  default     = ""
}

variable "public_ip_name_override" {
  description = "Override for the name used in resource.azurerm_public_ip.default"
  type        = string
  default     = ""
}

variable "jumpbox_public_ip_name_override" {
  description = "Override for the name used in resource.azurerm_public_ip.jumpbox"
  type        = string
  default     = ""
}

variable "bastion_public_ip_name_override" {
  description = "Override for the name used in resource.azurerm_public_ip.ip_bastion_host"
  type        = string
  default     = ""
}

variable "vnet_nsg_name_override" {
  description = "Override for the name used in resource.azurerm_network_security_group.nsg_vnet"
  type        = string
  default     = ""
}

variable "jumpbox_nsg_name_override" {
  description = "Override for the name used in resource.azurerm_network_security_group.jumpbox"
  type        = string
  default     = ""
}

variable "bastion_host_name_override" {
  description = "Override for the name used in resource.azurerm_bastion_host.bastion"
  type        = string
  default     = ""
}

variable "vm_nic_name_override" {
  description = "Override for the name used in resource.azurerm_network_interface.vm_nic"
  type        = string
  default     = ""
}

variable "linux_vm_name_override" {
  description = "Override for the name used in resource.azurerm_linux_virtual_machine.linux_vm"
  type        = string
  default     = ""
}

variable "database_private_dns_zone_name_override" {
  description = "Override for the name used in resource.azurerm_private_dns_zone.database"
  type        = string
  default     = ""
}

variable "database_dns_link_name_override" {
  description = "Override for the name used in resource.azurerm_private_dns_zone_virtual_network_link.database"
  type        = string
  default     = ""
}
