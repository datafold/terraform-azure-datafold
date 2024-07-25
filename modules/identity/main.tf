resource "azurerm_user_assigned_identity" "default" {
  name                = "${var.deployment_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}
