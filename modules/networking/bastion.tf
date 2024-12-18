
resource "azurerm_public_ip" "ip_bastion_host" {
  name                = "${var.deployment_name}-ip-bastion-host"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion"
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
  name                = "vm-nic"
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
  name                = "${var.deployment_name}-jumpbox-vm"
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