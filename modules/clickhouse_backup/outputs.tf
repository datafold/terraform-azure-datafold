output "azure_blob_account_name" {
  value = azurerm_storage_account.storage.name
}

output "azure_blob_account_key" {
  value = azurerm_storage_account.storage.primary_access_key
}

output "azure_blob_container" {
  value = azurerm_storage_container.clickhouse_backup.name
}

output "storage_account_id" {
  value = azurerm_storage_account.storage.id
}

output "memgraph_backup_container" {
  value = var.memgraph_backup_enabled ? azurerm_storage_container.memgraph_backup[0].name : null
}
