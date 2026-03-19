locals {
  storage_account_name = var.storage_account_name_override != "" ? var.storage_account_name_override : replace("${var.deployment_name}tmppgbak", "-", "")
  container_name       = var.container_name_override != "" ? var.container_name_override : "${var.deployment_name}-temporal-pg-backup"
}

resource "azurerm_storage_account" "temporal_backup" {
  name                            = local.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "temporal_backup" {
  name                  = local.container_name
  storage_account_id    = azurerm_storage_account.temporal_backup.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "temporal_backup" {
  storage_account_id = azurerm_storage_account.temporal_backup.id

  rule {
    name    = "backup_retention"
    enabled = true
    filters {
      blob_types   = ["blockBlob"]
      prefix_match = [local.container_name]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.backup_lifecycle_expiration_days
      }
    }
  }
}
