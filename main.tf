# Create a resource group
resource "azurerm_resource_group" "mtc-rg" {
  name     = "rg-sanyi"
  location = "West Europe"
  tags = {
    environment = "dev"
  }
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
