resource "azurerm_storage_account" "storage" {
  name                     = replace("${var.deployment_name}-storage", "-", "")
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
  name                  = "${var.deployment_name}-clickhouse-backup"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# ============PrivateLink for Storage Account====================
resource "azurerm_private_dns_zone" "storage_account_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_endpoint" "storage" {
  name                = "${var.deployment_name}-pe-storage"
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
  name                  = "link-privateDnsZone-to-vnet"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account_dns.name
  virtual_network_id    = var.vpc.id
}
