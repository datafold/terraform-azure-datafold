locals {
  storage_account_name          = var.storage_account_name_override != "" ? var.storage_account_name_override : replace("${var.deployment_name}-storage", "-", "")
  clickhouse_backup_container_name = var.clickhouse_backup_container_name_override != "" ? var.clickhouse_backup_container_name_override : "${var.deployment_name}-clickhouse-backup"
  storage_private_dns_zone_name = var.storage_private_dns_zone_name_override != "" ? var.storage_private_dns_zone_name_override : "privatelink.blob.core.windows.net"
  storage_private_endpoint_name = var.storage_private_endpoint_name_override != "" ? var.storage_private_endpoint_name_override : "${var.deployment_name}-pe-storage"
  storage_dns_link_name        = var.storage_dns_link_name_override != "" ? var.storage_dns_link_name_override : "link-privateDnsZone-to-vnet"
}

resource "azurerm_storage_account" "storage" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "BlockBlobStorage"
  account_tier             = "Premium"
  account_replication_type = "LRS"

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity.id]
  }
}

resource "azurerm_storage_container" "clickhouse_backup" {
  name                 = local.clickhouse_backup_container_name
  storage_account_id   = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# ============PrivateLink for Storage Account====================
resource "azurerm_private_dns_zone" "storage_account_dns" {
  name                = local.storage_private_dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_endpoint" "storage" {
  name                = local.storage_private_endpoint_name
  resource_group_name = var.resource_group_name
  location            = var.location

  subnet_id = var.private_endpoint_storage_subnet.id

  private_service_connection {
    name                           = format("pe-2%s", azurerm_storage_account.storage.name)
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_account_dns.id]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_account_link" {
  name                  = local.storage_dns_link_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account_dns.name
  virtual_network_id    = var.vpc.id
}
