resource "azurerm_network_security_group" "nsg_vnet" {
  name                = "network-security-group"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_network_security_group" "jumpbox" {
  name                = "${var.deployment_name}-jumpbox-sg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_rule" "jumpbox_8443" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "8443"
  direction                   = "Inbound"
  name                        = "AllowCidrBlockCustomInbound"
  network_security_group_name = "${azurerm_network_security_group.jumpbox.name}"
  priority                    = "120"
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name
  source_address_prefixes     = var.k8s_public_access_cidrs
  source_port_range           = "8443"
}

resource "azurerm_network_security_rule" "jumpbox_443" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "443"
  direction                   = "Inbound"
  name                        = "AllowCidrBlockHTTPSInbound"
  network_security_group_name = "${azurerm_network_security_group.jumpbox.name}"
  priority                    = "100"
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name
  source_address_prefixes     = var.k8s_public_access_cidrs
  source_port_range           = "443"
}

resource "azurerm_network_security_rule" "jumpbox_22" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "22"
  direction                   = "Inbound"
  name                        = "AllowCidrBlockSSHInbound"
  network_security_group_name = "${azurerm_network_security_group.jumpbox.name}"
  priority                    = "110"
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name
  source_address_prefixes     = var.k8s_public_access_cidrs
  source_port_range           = "22"
}
