# Create a virtual network within the resource group
resource "azurerm_virtual_network" "mtc-vn" {
  name                = "mtc-network"
  resource_group_name = var.rg_name
  location            = var.rg_location
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "dev"
  }
}


resource "azurerm_subnet" "mtc-subnet-1" {
  name                 = "mtc-subnet-1"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.mtc-vn.name
  address_prefixes     = ["10.0.10.0/24"]
}


resource "azurerm_public_ip" "mtc-ip" {
  name                = "mtc-ip"
  resource_group_name = var.rg_name
  location            = var.rg_location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}


resource "azurerm_network_interface" "mtc-nic" {
  name                = "mtc-nic"
  location            = var.rg_location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mtc-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mtc-ip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet_network_security_group_association" "mtc-sga" {
  subnet_id                 = azurerm_subnet.mtc-subnet-1.id
  network_security_group_id = azurerm_network_security_group.mtc-sg.id
}

resource "azurerm_network_security_group" "mtc-sg" {
  name                = "mtc-sg"
  location            = var.rg_location
  resource_group_name = var.rg_name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "mtc-vm" {
  name                = "mtc-machine"
  resource_group_name = var.rg_name
  location            = var.rg_location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.mtc-nic.id
  ]

  custom_data = filebase64("customdata.tpl")

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

  provisioner "local-exec" {
    command = templatefile("${var.os_host}-ssh-script.tpl", {
      hostname     = self.public_ip_address,
      user         = "adminuser",
      identityfile = "~/.ssh/id_rsa"
    })
    interpreter = var.os_host ==   "windows" ? ["bash", "-c"] : ["PowerShell", "-Command"]
  }

  tags = {
    environment = "dev"
  }
}