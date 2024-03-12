output "public_ip_address" {
  value = "module.subnet.vm.name: ${data.azurerm_public_ip.mtc-ip-data.ip_address}"

}