resource "azurerm_network_security_group" "nsg_vnet" {
  name                = "network-security-group"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}