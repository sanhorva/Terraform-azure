resource "azurerm_service_plan" "sanyi-sp" {
  name                = "sanyi-appserviceplan"
  location            = var.rg_location
  resource_group_name = var.rg_name
  os_type             = "Linux"
  sku_name            = "S1"
}


resource "azurerm_linux_web_app" "sanyi-app" {
  name                = "sanyi-webapp"
  location            = var.rg_location
  resource_group_name = var.rg_name
  service_plan_id     = azurerm_service_plan.sanyi-sp.id
  site_config {
    #linux_fx_version = "PYTHON|3.8"  # Install Python 3.8 runtime
    #linux_fx_version = "NODE|12"
  }
}

