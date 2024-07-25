resource "azurerm_public_ip" "default" {
  name                = "${var.deployment_name}-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  domain_name_label   = var.deployment_name

  tags = var.tags
}

locals {
  backend_address_pool_name      = "${var.deployment_name}-beap"
  frontend_port_name             = "${var.deployment_name}-feport"
  frontend_ip_configuration_name = "${var.deployment_name}-feip"
  gateway_ip_configuration_name  = "${var.deployment_name}-gwip"
  http_setting_name              = "${var.deployment_name}-be-htst"
  listener_name                  = "${var.deployment_name}-httplstn"
  request_routing_rule_name      = "${var.deployment_name}-rqrt"
  redirect_configuration_name    = "${var.deployment_name}-rdrcfg"
  app_gateway_name               = "${var.deployment_name}-ag-private-link"
}



resource "azurerm_application_gateway" "default" {
  name                = local.app_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags

  # identity {
  #   type         = "UserAssigned"
  #   identity_ids = [azurerm_user_assigned_identity.default.id]
  # }

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
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.default.id
  }

  frontend_ip_configuration {
    name                            = "${local.frontend_ip_configuration_name}-private"
    subnet_id                       = var.app_gw_subnet.id
    private_ip_address_allocation   = "Static"
    private_ip_address              = var.private_ip_address
    private_link_configuration_name = "${var.deployment_name}-private-link"
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
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 1
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

  http_listener {
    name                           = "${local.listener_name}-private"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}-private"
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-private"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-private"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 2
  }

  lifecycle {
    # K8S will be changing all of these settings so we ignore them.
    # We really only needed this resource to assign a known public IP.
    ignore_changes = [
      ssl_certificate,
      request_routing_rule,
      probe,
      url_path_map,
      frontend_port,
      http_listener,
      backend_http_settings,
      backend_address_pool,
      private_link_configuration,
      tags
    ]
  }
}
