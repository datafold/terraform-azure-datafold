resource "azurerm_public_ip" "default" {
  name                = "${var.deployment_name}-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  domain_name_label   = var.deployment_name

  tags = var.tags
}