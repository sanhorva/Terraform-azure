# Create a resource group
resource "azurerm_resource_group" "mtc-rg" {
  name     = "rg-sanyi"
  location = "West Europe"
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

resource "azurerm_container_registry" "acr" {
  name                = "crsanyi"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = azurerm_resource_group.mtc-rg.location
  sku                 = "Standard"
  admin_enabled       = false
}

data "azurerm_public_ip" "mtc-ip-data" {
  name                = module.subnet.pip.name
  resource_group_name = azurerm_resource_group.mtc-rg.name
  depends_on          = [module.subnet]
}


module "webserver" {
  source      = "./Modules/webserver"
  rg_location = azurerm_resource_group.mtc-rg.location
  rg_name     = azurerm_resource_group.mtc-rg.name
}


module "subnet" {
  source      = "./Modules/subnet"
  rg_location = azurerm_resource_group.mtc-rg.location
  rg_name     = azurerm_resource_group.mtc-rg.name
  os_host     = var.os_host
}


#module "subnet" {
#  source = "./Modules/subnet"
#  rg_location = azurerm_resource_group.mtc-rg.location
#  rg_name = azurerm_resource_group.mtc-rg.name
#  network_id = var.network_id
#  public_ip_name = var.public_ip_name
# }





# Create a virtual network within the resource group
#resource "azurerm_virtual_network" "mtc-vn" {
#  name                = "mtc-network"
#  resource_group_name = azurerm_resource_group.mtc-rg.name
#  location            = azurerm_resource_group.mtc-rg.location
#  address_space       = ["10.0.0.0/16"]
#
#  tags = {
#    environment = "dev"
#  }
#}
#
#
#resource "azurerm_subnet" "mtc-subnet-1" {
#  name                 = "mtc-subnet-1"
#  resource_group_name  = azurerm_resource_group.mtc-rg.name
#  virtual_network_name = azurerm_virtual_network.mtc-vn.name
#  address_prefixes     = ["10.0.10.0/24"]
#}
#
#
#resource "azurerm_public_ip" "mtc-ip" {
#  name                = "mtc-ip"
#  resource_group_name = azurerm_resource_group.mtc-rg.name
#  location            = azurerm_resource_group.mtc-rg.location
#  allocation_method   = "Dynamic"
#
#  tags = {
#    environment = "dev"
#  }
#}
#
#
#resource "azurerm_network_interface" "mtc-nic" {
#  name                = "mtc-nic"
#  location            = azurerm_resource_group.mtc-rg.location
#  resource_group_name = azurerm_resource_group.mtc-rg.name
#
#  ip_configuration {
#    name                          = "internal"
#    subnet_id                     = azurerm_subnet.mtc-subnet-1.id
#    private_ip_address_allocation = "Dynamic"
#    public_ip_address_id          = azurerm_public_ip.mtc-ip.id
#  }
#
#  tags = {
#    environment = "dev"
#  }
#}
#resource "azurerm_subnet_network_security_group_association" "mtc-sga" {
#  subnet_id                 = azurerm_subnet.mtc-subnet-1.id
#  network_security_group_id = azurerm_network_security_group.mtc-sg.id
#}
#
#resource "azurerm_network_security_group" "mtc-sg" {
#  name                = "mtc-sg"
#  location            = azurerm_resource_group.mtc-rg.location
#  resource_group_name = azurerm_resource_group.mtc-rg.name
#
#  tags = {
#    environment = "dev"
#  }
#}
#