locals {
  identity_name = var.identity_name_override != "" ? var.identity_name_override : "${var.deployment_name}-identity"
}

resource "azurerm_user_assigned_identity" "default" {
  name                = local.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}
