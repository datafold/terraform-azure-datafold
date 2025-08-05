locals {
  database_private_dns_zone_name = var.database_private_dns_zone_name_override != "" ? var.database_private_dns_zone_name_override : "${var.deployment_name}.postgres.database.azure.com"
  database_dns_link_name         = var.database_dns_link_name_override != "" ? var.database_dns_link_name_override : "${var.deployment_name}-database"
}

# ============PrivateLink for database====================

resource "azurerm_private_dns_zone" "database" {
  name                = local.database_private_dns_zone_name
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "database" {
  name                  = local.database_dns_link_name
  private_dns_zone_name = azurerm_private_dns_zone.database.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = azurerm_virtual_network.vnet.id

  tags = var.tags

  depends_on = [
    azurerm_private_dns_zone.database
  ]
}
