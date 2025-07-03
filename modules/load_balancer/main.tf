locals {
  backend_address_pool_name      = "${var.deployment_name}-beap"
  frontend_ip_configuration_name = "${var.deployment_name}-feip"
  gateway_ip_configuration_name  = "${var.deployment_name}-gwip"
  http_setting_name              = "${var.deployment_name}-be-htst-http"
  request_routing_rule_name_http = "${var.deployment_name}-rqrt-http"
  app_gateway_name               = "${var.deployment_name}-ag-private-link"
}

resource "azurerm_application_gateway" "default" {
  name                = local.app_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags

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

  frontend_port {
    name = "port_443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = var.public_ip_id
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
    name                           = "http"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "https"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "port_443"
    protocol                       = "Https"
    require_sni                    = "false"
    ssl_certificate_name           = var.ssl_cert_name
  }

  request_routing_rule {
    name                        = "http-redirect"
    rule_type                   = "Basic"
    http_listener_name          = "http"
    redirect_configuration_name = "http-to-https"
    priority                    = 90
  }

  redirect_configuration {
    name                 = "http-to-https"
    redirect_type        = "Permanent"
    target_listener_name = "https"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name_http
    rule_type                  = "Basic"
    http_listener_name         = "https"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 100
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

  ssl_certificate {
    key_vault_secret_id = var.ssl_cert_id
    name                = var.ssl_cert_name
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"  # Latest secure policy
  }

  lifecycle {
    # K8S will be changing all of these settings so we ignore them.
    # We really only needed this resource to assign a known public IP.
    ignore_changes = [
      request_routing_rule,
      probe,
      backend_http_settings,
      backend_address_pool,
      url_path_map,
      frontend_port,
      http_listener,
      private_link_configuration,
      tags,
    ]
  }
}
