output "postgres_database_name" {
  value = azurerm_postgresql_flexible_server_database.example.name
}

output "postgres_password" {
  value = random_password.db_password.result
}

output "postgres_host" {
  value = azurerm_postgresql_flexible_server.example.fqdn
}

output "postgres_username" {
  value = azurerm_postgresql_flexible_server.example.administrator_login
}