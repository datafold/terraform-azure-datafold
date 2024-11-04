resource "azurerm_public_ip" "default" {
  count               = var.lb_is_public ? 1 : 0

  name                = "${var.deployment_name}-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  domain_name_label   = var.deployment_name

  tags = var.tags
}