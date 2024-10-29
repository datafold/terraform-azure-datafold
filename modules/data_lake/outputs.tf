output "adls_account_name" {
  value = azurerm_storage_account.adls.name
}

output "adls_account_key" {
  value = azurerm_storage_account.adls.primary_access_key
}

output "adls_filesystem" {
  value = azurerm_storage_data_lake_gen2_filesystem.adls.name
}