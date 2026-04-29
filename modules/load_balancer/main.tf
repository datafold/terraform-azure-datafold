locals {
  backend_address_pool_name      = "${var.deployment_name}-beap"
  frontend_ip_configuration_name = "${var.deployment_name}-feip"
  gateway_ip_configuration_name  = "${var.deployment_name}-gwip"
  http_setting_name              = "${var.deployment_name}-be-htst-http"
  request_routing_rule_name_http = "${var.deployment_name}-rqrt-http"
  app_gateway_name               = var.application_gateway_name_override != "" ? var.application_gateway_name_override : "${var.deployment_name}-ag-private-link"
}

resource "azurerm_application_gateway" "default" {
  name                = local.app_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags

  # --- Things TF owns ---

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity.id]
  }

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 5
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = var.app_gw_subnet.id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = var.public_ip_id
  }

  ssl_certificate {
    name                = var.ssl_cert_name
    key_vault_secret_id = var.ssl_cert_id
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }

  private_link_configuration {
    name = "${var.deployment_name}-private-link"

    ip_configuration {
      name                          = "primary"
      subnet_id                     = var.app_gw_subnet.id
      private_ip_address_allocation = "Dynamic"
      primary                       = true
    }
  }

  # --- Stubs to satisfy the API; AGIC will replace/augment ---

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "stub-listener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "stub-rule"
    rule_type                  = "Basic"
    http_listener_name         = "stub-listener"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 100
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      request_routing_rule,
      url_path_map,
      probe,
      redirect_configuration,
      rewrite_rule_set,
      frontend_port,
      tags,
    ]
  }
}
