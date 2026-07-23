locals {
  storage_account_name             = var.storage_account_name_override != "" ? var.storage_account_name_override : replace("${var.deployment_name}-storage", "-", "")
  clickhouse_backup_container_name = var.clickhouse_backup_container_name_override != "" ? var.clickhouse_backup_container_name_override : "${var.deployment_name}-clickhouse-backup"
  memgraph_backup_container_name   = var.memgraph_backup_container_name_override != "" ? var.memgraph_backup_container_name_override : "${var.deployment_name}-memgraph-backup"
  storage_private_dns_zone_name    = var.storage_private_dns_zone_name_override != "" ? var.storage_private_dns_zone_name_override : "privatelink.blob.core.windows.net"
  storage_private_endpoint_name    = var.storage_private_endpoint_name_override != "" ? var.storage_private_endpoint_name_override : "${var.deployment_name}-pe-storage"
  storage_dns_link_name            = var.storage_dns_link_name_override != "" ? var.storage_dns_link_name_override : "link-privateDnsZone-to-vnet"
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
  name                  = local.clickhouse_backup_container_name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# Memgraph DR backups (datafold repo: docs/decisions/choose-memgraph-dr-architecture.md).
# The nightly backup job in the app uploads each graph's newest snapshot here;
# the lifecycle rule below is the entire retention policy (the app never prunes).
resource "azurerm_storage_container" "memgraph_backup" {
  count = var.memgraph_backup_enabled ? 1 : 0

  name                  = local.memgraph_backup_container_name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# Azure allows exactly ONE management policy resource per storage account — it
# owns the account's whole lifecycle document. Every retention rule for this
# account must therefore live in this resource; a second
# azurerm_storage_management_policy anywhere (another module, a deployment dir)
# would silently wipe these rules on each alternating apply.
resource "azurerm_storage_management_policy" "clickhouse_backup" {
  storage_account_id = azurerm_storage_account.storage.id

  rule {
    name    = "backup_retention"
    enabled = true
    filters {
      blob_types   = ["blockBlob"]
      prefix_match = [local.clickhouse_backup_container_name]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.backup_lifecycle_expiration_days
      }
    }
  }

  dynamic "rule" {
    for_each = var.memgraph_backup_enabled ? [1] : []
    content {
      name    = "memgraph_backup_retention"
      enabled = true
      filters {
        blob_types   = ["blockBlob"]
        prefix_match = [local.memgraph_backup_container_name]
      }
      actions {
        base_blob {
          delete_after_days_since_modification_greater_than = var.memgraph_backup_lifecycle_expiration_days
        }
      }
    }
  }
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
