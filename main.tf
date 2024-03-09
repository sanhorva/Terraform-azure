# Create a resource group
resource "azurerm_resource_group" "mtc-rg" {
  name     = "rg-sanyi"
  location = "West Europe"
  tags = {
    environment = "dev"
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "mtc-vn" {
  name                = "mtc-network"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = azurerm_resource_group.mtc-rg.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "mtc-vm" {
  name                = "mtc-machine"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = azurerm_resource_group.mtc-rg.location
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
    interpreter = var.os_host == "windows" ? ["bash", "-c"] : ["PowerShell", "-Command"]
  }

  tags = {
    environment = "dev"
  }
}

data "azurerm_public_ip" "mtc-ip-data" {
  name                = azurerm_public_ip.mtc-ip.name
  resource_group_name = azurerm_resource_group.mtc-rg.name

}
resource "azurerm_subnet" "mtc-subnet-1" {
  name                 = "mtc-subnet-1"
  resource_group_name  = azurerm_resource_group.mtc-rg.name
  virtual_network_name = azurerm_virtual_network.mtc-vn.name
  address_prefixes     = ["10.0.10.0/24"]
}

resource "azurerm_container_registry" "acr" {
  name                = "crsanyi"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = azurerm_resource_group.mtc-rg.location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "azurerm_service_plan" "sanyi-sp" {
  name                = "sanyi-appserviceplan"
  location            = azurerm_resource_group.mtc-rg.location
  resource_group_name = azurerm_resource_group.mtc-rg.name
  os_type             = "Linux"
  sku_name            = "S1"
}


resource "azurerm_linux_web_app" "sanyi-app" {
  name                = "sanyi-webapp"
  location            = azurerm_resource_group.mtc-rg.location
  resource_group_name = azurerm_resource_group.mtc-rg.name
  service_plan_id     = azurerm_service_plan.sanyi-sp.id
  site_config {
    #linux_fx_version = "PYTHON|3.8"  # Install Python 3.8 runtime
    #linux_fx_version = "NODE|12"
  }
}


resource "azurerm_network_security_group" "mtc-sg" {
  name                = "mtc-sg"
  location            = azurerm_resource_group.mtc-rg.location
  resource_group_name = azurerm_resource_group.mtc-rg.name

  tags = {
    environment = "dev"
  }
}

# resource "azurerm_network_security_rule" "mtc-dev-rule" {
#   name                        = "mtc-dev-rule"
#   priority                    = 100
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.mtc-rg.name
#   network_security_group_name = azurerm_network_security_group.mtc-sg.name
# }

resource "azurerm_subnet_network_security_group_association" "mtc-sga" {
  subnet_id                 = azurerm_subnet.mtc-subnet-1.id
  network_security_group_id = azurerm_network_security_group.mtc-sg.id
}

resource "azurerm_kubernetes_cluster" "sanyi-aks" {
  name                = "aks-sanyi"
  location            = azurerm_resource_group.mtc-rg.location
  resource_group_name = azurerm_resource_group.mtc-rg.name
  dns_prefix          = "s-aks-net"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_public_ip" "mtc-ip" {
  name                = "mtc-ip"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = azurerm_resource_group.mtc-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "mtc-nic" {
  name                = "mtc-nic"
  location            = azurerm_resource_group.mtc-rg.location
  resource_group_name = azurerm_resource_group.mtc-rg.name

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

output "public_ip_address" {
  value = "${azurerm_linux_virtual_machine.mtc-vm.name}: ${data.azurerm_public_ip.mtc-ip-data.ip_address}"

}