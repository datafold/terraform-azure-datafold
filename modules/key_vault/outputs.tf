output "etcd_key_id" {
  value = azurerm_key_vault_key.etcd.id
}

output "ssl_cert_id" {
  value = azurerm_key_vault_certificate.ssl.versionless_secret_id
}

output "vault" {
  value = azurerm_key_vault.default
}
