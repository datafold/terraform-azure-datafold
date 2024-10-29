# ============Virtual network with subnets================================================
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.deployment_name}-network"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vpc_cidrs

  tags = var.tags
}
resource "azurerm_subnet" "aks_subnet" {
  resource_group_name  = var.resource_group_name
  name                 = "aks-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.aks_subnet_cidrs
}
resource "azurerm_subnet" "private_endpoint_storage" {
  resource_group_name  = var.resource_group_name
  name                 = "private-endpoint-storage"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.private_endpoint_storage_subnet_cidrs
}
resource "azurerm_subnet" "private_endpoint_adls" {
  count = length(var.private_endpoint_adls_subnet_cidrs) > 0 ? 1 : 0

  resource_group_name  = var.resource_group_name
  name                 = "private-endpoint-adls"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.private_endpoint_adls_subnet_cidrs
}
resource "azurerm_subnet" "azure_bastion_subnet" {
  resource_group_name  = var.resource_group_name
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.azure_bastion_subnet_cidrs
}
resource "azurerm_subnet" "vm_bastion_subnet" {
  resource_group_name  = var.resource_group_name
  name                 = "vm-bastion-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.vm_bastion_subnet_cidrs
}
resource "azurerm_subnet" "database_subnet" {
  resource_group_name  = var.resource_group_name
  name                 = "database-subnet"
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
  name                 = "app-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.app_subnet_cidrs
}
resource "azurerm_subnet" "app_gw_subnet" {
  resource_group_name  = var.resource_group_name
  name                 = "app-gw-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.app_gw_subnet_cidrs

  private_link_service_network_policies_enabled = false
}
