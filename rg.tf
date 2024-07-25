locals {
  resource_group_name = coalesce(var.resource_group_name, "${var.deployment_name}-rg")
}

# Create a resource group
resource "azurerm_resource_group" "default" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location

  tags = var.resource_group_tags
}

data "azurerm_resource_group" "default" {
  provider = azurerm

  name = local.resource_group_name

  depends_on = [azurerm_resource_group.default]
}