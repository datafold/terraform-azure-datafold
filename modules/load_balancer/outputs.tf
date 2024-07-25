output "address" {
  value = azurerm_public_ip.default.ip_address
}

output "gateway" {
  value = azurerm_application_gateway.default
}

output "gateway_id" {
  value = azurerm_application_gateway.default.id
}

output "domain_name" {
  value = azurerm_public_ip.default.fqdn
}

output "load_balancer_ips" {
  value = azurerm_public_ip.default.ip_address
}
