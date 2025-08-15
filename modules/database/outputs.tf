output "postgres_database_name" {
  value = var.use_existing_database ? var.existing_postgresql_database_name : azurerm_postgresql_flexible_server_database.main[0].name
}

output "postgres_password" {
  value = var.use_existing_database ? "" : random_password.db_password[0].result
  description = "Password is only available for newly created databases. For existing databases, use the original password."
  sensitive = true
}

output "postgres_host" {
  value = var.use_existing_database ? (
    length(azurerm_private_endpoint.postgresql) > 0 ? 
    azurerm_private_endpoint.postgresql[0].private_dns_zone_configs[0].record_sets[0].fqdn :
    data.azurerm_postgresql_flexible_server.existing[0].fqdn
  ) : azurerm_postgresql_flexible_server.main[0].fqdn
  description = "PostgreSQL server hostname. For existing databases with private endpoint, this will be the private endpoint FQDN."
}

output "postgres_username" {
  value = var.use_existing_database ? data.azurerm_postgresql_flexible_server.existing[0].administrator_login : azurerm_postgresql_flexible_server.main[0].administrator_login
}

output "private_endpoint_ip" {
  value = var.use_existing_database && length(azurerm_private_endpoint.postgresql) > 0 ? azurerm_private_endpoint.postgresql[0].private_service_connection[0].private_ip_address : null
  description = "Private IP address of the PostgreSQL private endpoint (only available when using existing database)"
}

output "vnet_peering_status" {
  value = var.use_existing_database ? {
    ours_to_existing = length(azurerm_virtual_network_peering.ours_to_existing) > 0 ? azurerm_virtual_network_peering.ours_to_existing[0].name : null
    existing_to_ours = length(azurerm_virtual_network_peering.existing_to_ours) > 0 ? azurerm_virtual_network_peering.existing_to_ours[0].name : null
  } : null
  description = "VNet peering information when using existing database"
}