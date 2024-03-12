output "pip" {
    value =  azurerm_public_ip.mtc-ip 
}

output "vm" {
    value = azurerm_linux_virtual_machine.mtc-vm
}

