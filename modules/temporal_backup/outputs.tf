output "storage_account_name" {
  value = azurerm_storage_account.temporal_backup.name
}

output "storage_account_id" {
  value = azurerm_storage_account.temporal_backup.id
}

output "container_name" {
  value = azurerm_storage_container.temporal_backup.name
}
