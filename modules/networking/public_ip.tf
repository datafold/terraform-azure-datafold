resource "azurerm_public_ip" "default" {
  count               = var.lb_is_public ? 1 : 0

  name                = "${var.deployment_name}-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  domain_name_label   = var.deployment_name

  tags = var.tags
}

resource "azurerm_public_ip" "jumpbox" {
  count                   = var.private_cluster_enabled ? 1 : 0

  allocation_method       = "Static"
  ddos_protection_mode    = "VirtualNetworkInherited"
  idle_timeout_in_minutes = "4"
  ip_version              = "IPv4"
  name                    = "${var.deployment_name}-ip-jumpbox"
  resource_group_name     = var.resource_group_name
  location                = var.location
  sku                     = "Standard"
  sku_tier                = "Regional"

  tags = var.tags
}