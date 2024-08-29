output "gateway" {
  value = azurerm_application_gateway.default
}

output "gateway_id" {
  value = azurerm_application_gateway.default.id
}
