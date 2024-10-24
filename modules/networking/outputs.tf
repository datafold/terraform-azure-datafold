output "vpc" {
  value = azurerm_virtual_network.vnet
}

output "aks_subnet" {
  value = azurerm_subnet.aks_subnet
}

output "app_subnet" {
  value = azurerm_subnet.app_subnet
}

output "private_endpoint_storage_subnet" {
  value = azurerm_subnet.private_endpoint_storage
}

output "database_subnet" {
  value = azurerm_subnet.database_subnet
}

output "app_gw_subnet" {
  value = azurerm_subnet.app_gw_subnet
}

output "vpc_cidr" {
  value = azurerm_virtual_network.vnet.address_space[0]
}

output "database_private_dns_zone_id" {
  value = azurerm_private_dns_zone.database.id
}

output "public_ip" {
  value = azurerm_public_ip.default
}
