output "pip" {
    value =  azurerm_public_ip.mtc-ip    # tomap({name = "127.0.0.1"}) 
}

output "vm" {
    value = azurerm_linux_virtual_machine.mtc-vm
}

