# -------------------------
# Public IP of the MySQL VM
# -------------------------
output "mysql_vm_public_ip" {
  description = "Public IP address of the MySQL VM"
  value       = azurerm_public_ip.mysql_vm_pip.ip_address
}

# -------------------------
# Private IP of the MySQL VM
# -------------------------
output "mysql_vm_private_ip" {
  description = "Private IP address of the MySQL VM"
  value       = azurerm_network_interface.mysql_vm_nic.private_ip_addresses[0]
}

# -------------------------
# Remove from known hosts SSH command
# -------------------------
output "ssh_remove_from_known_hosts_command" {
  description = "SSH command to remove VM from known hosts"
  value       = "ssh-keygen -f \"/home/fernando/.ssh/known_hosts\" -R ${azurerm_public_ip.mysql_vm_pip.ip_address}"
}

# -------------------------
# SSH command
# -------------------------
output "ssh_command" {
  description = "SSH command to access the VM"
  value       = "ssh azureuser@${azurerm_public_ip.mysql_vm_pip.ip_address}"
}

# -------------------------
# MySQL connection string
# -------------------------
output "mysql_connection_string" {
  description = "Connection string for MySQL"
  sensitive   = true
  value       = "mysql -h ${azurerm_network_interface.mysql_vm_nic.private_ip_addresses[0]} -u root -p${var.mysql_password} db_migration_ddbb"
}