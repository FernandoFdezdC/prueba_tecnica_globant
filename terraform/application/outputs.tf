output "app_vm_public_ip" {
  description = "Public IP of the application VM"
  value       = azurerm_linux_virtual_machine.app_vm.public_ip_address
}

output "app_url" {
  description = "URL to access the API documentation"
  value       = "http://${azurerm_linux_virtual_machine.app_vm.public_ip_address}:${local.app_port}/docs"
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh azureuser@${azurerm_linux_virtual_machine.app_vm.public_ip_address}"
}