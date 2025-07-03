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

output "private_endpoint_adls_subnet" {
  value = length(azurerm_subnet.private_endpoint_adls) > 0 ? azurerm_subnet.private_endpoint_adls[0] : null
}

output "database_subnet" {
  value = azurerm_subnet.database_subnet
}

output "app_gw_subnet" {
  value = azurerm_subnet.app_gw_subnet
}

output "vpc_cidr" {
  value = one(azurerm_virtual_network.vnet.address_space)
}

output "database_private_dns_zone_id" {
  value = azurerm_private_dns_zone.database.id
}

output "public_ip_id" {
  value = var.lb_is_public ? azurerm_public_ip.default[0].id : null
}

output "public_ip" {
  value = var.lb_is_public ? azurerm_public_ip.default[0].ip_address : null
}

output "public_ip_jumpbox" {
  value = azurerm_public_ip.jumpbox[0].ip_address
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}
