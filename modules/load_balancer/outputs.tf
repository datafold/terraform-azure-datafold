output "gateway" {
  value = azurerm_application_gateway.default
}

output "gateway_id" {
  value = azurerm_application_gateway.default.id
}

output "lb_ip" {
  description = "IP of the load balancer"
  value       = var.lb_is_public ? var.public_ip : azurerm_application_gateway.default.frontend_ip_configuration[0].private_ip_address
}
