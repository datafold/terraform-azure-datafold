output "azure_blob_account_name" {
  value = azurerm_storage_account.storage.name
}

output "azure_blob_account_key" {
  value = azurerm_storage_account.storage.primary_access_key
}

output "azure_blob_container" {
  value = azurerm_storage_container.clickhouse_backup.name
}
