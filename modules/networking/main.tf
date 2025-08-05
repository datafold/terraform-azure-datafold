locals {
  virtual_network_name                       = var.virtual_network_name_override != "" ? var.virtual_network_name_override : "${var.deployment_name}-network"
  aks_subnet_name                           = var.aks_subnet_name_override != "" ? var.aks_subnet_name_override : "aks-subnet"
  private_endpoint_storage_subnet_name      = var.private_endpoint_storage_subnet_name_override != "" ? var.private_endpoint_storage_subnet_name_override : "private-endpoint-storage"
  private_endpoint_adls_subnet_name         = var.private_endpoint_adls_subnet_name_override != "" ? var.private_endpoint_adls_subnet_name_override : "private-endpoint-adls"
  azure_bastion_subnet_name                 = var.azure_bastion_subnet_name_override != "" ? var.azure_bastion_subnet_name_override : "AzureBastionSubnet"
  vm_bastion_subnet_name                    = var.vm_bastion_subnet_name_override != "" ? var.vm_bastion_subnet_name_override : "vm-bastion-subnet"
  database_subnet_name                      = var.database_subnet_name_override != "" ? var.database_subnet_name_override : "database-subnet"
  app_subnet_name                           = var.app_subnet_name_override != "" ? var.app_subnet_name_override : "app-subnet"
  app_gw_subnet_name                        = var.app_gw_subnet_name_override != "" ? var.app_gw_subnet_name_override : "app-gw-subnet"
}

# ============Virtual network with subnets================================================
resource "azurerm_virtual_network" "vnet" {
  name                = local.virtual_network_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vpc_cidrs

  tags = var.tags
}
resource "azurerm_subnet" "aks_subnet" {
  resource_group_name  = var.resource_group_name
  name                 = local.aks_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.aks_subnet_cidrs
}
resource "azurerm_subnet" "private_endpoint_storage" {
  resource_group_name  = var.resource_group_name
  name                 = local.private_endpoint_storage_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.private_endpoint_storage_subnet_cidrs
}
resource "azurerm_subnet" "private_endpoint_adls" {
  count = length(var.private_endpoint_adls_subnet_cidrs) > 0 ? 1 : 0

  resource_group_name  = var.resource_group_name
  name                 = local.private_endpoint_adls_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.private_endpoint_adls_subnet_cidrs
}
resource "azurerm_subnet" "azure_bastion_subnet" {
  resource_group_name  = var.resource_group_name
  name                 = local.azure_bastion_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.azure_bastion_subnet_cidrs
}
resource "azurerm_subnet" "vm_bastion_subnet" {
  resource_group_name  = var.resource_group_name
  name                 = local.vm_bastion_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.vm_bastion_subnet_cidrs
}
resource "azurerm_subnet" "database_subnet" {
  resource_group_name  = var.resource_group_name
  name                 = local.database_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.database_subnet_cidrs

  service_endpoints = ["Microsoft.Storage"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.database]
}
resource "azurerm_subnet" "app_subnet" {
  resource_group_name  = var.resource_group_name
  name                 = local.app_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.app_subnet_cidrs
}
resource "azurerm_subnet" "app_gw_subnet" {
  resource_group_name  = var.resource_group_name
  name                 = local.app_gw_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.app_gw_subnet_cidrs

  private_link_service_network_policies_enabled = false
}
