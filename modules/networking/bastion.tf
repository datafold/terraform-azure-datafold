locals {
  bastion_public_ip_name = var.bastion_public_ip_name_override != "" ? var.bastion_public_ip_name_override : "${var.deployment_name}-ip-bastion-host"
  bastion_host_name      = var.bastion_host_name_override != "" ? var.bastion_host_name_override : "bastion"
  vm_nic_name           = var.vm_nic_name_override != "" ? var.vm_nic_name_override : "vm-nic"
  linux_vm_name         = var.linux_vm_name_override != "" ? var.linux_vm_name_override : "${var.deployment_name}-jumpbox-vm"
}

resource "azurerm_public_ip" "ip_bastion_host" {
  name                = local.bastion_public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_bastion_host" "bastion" {
  name                = local.bastion_host_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku                    = "Standard"
  copy_paste_enabled     = true
  file_copy_enabled      = true
  ip_connect_enabled     = true
  shareable_link_enabled = false
  tunneling_enabled      = true // Required for native client support

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.azure_bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.ip_bastion_host.id
  }

  tags = var.tags
}

#  ┏┓╻ ╻┏┳┓┏━┓┏┓ ┏━┓╻ ╻
#   ┃┃ ┃┃┃┃┣━┛┣┻┓┃ ┃┏╋┛
# ┗━┛┗━┛╹ ╹╹  ┗━┛┗━┛╹ ╹

resource "azurerm_network_interface" "vm_nic" {
  name                = local.vm_nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_bastion_subnet.id
    public_ip_address_id          = azurerm_public_ip.jumpbox[0].id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  ip_forwarding_enabled = "true"

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = local.linux_vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  custom_data         = var.jumpbox_custom_data
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = var.tags
}