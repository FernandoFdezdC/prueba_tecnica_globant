# -------------------------
# Public IP
# -------------------------
output "mysql_vm_public_ip" {
  description = "Public IP of the MySQL VM"
  value       = module.database.mysql_vm_public_ip
}

# -------------------------
# Private IP
# -------------------------
output "mysql_vm_private_ip" {
  description = "Private IP of the MySQL VM"
  value       = module.database.mysql_vm_private_ip
}

# -------------------------
# Remove from known hosts SSH command
# -------------------------
output "ssh_remove_from_known_hosts_command" {
  description = "SSH command to remove VM from known hosts"
  value       = module.database.ssh_remove_from_known_hosts_command
}

# -------------------------
# SSH command
# -------------------------
output "ssh_command" {
  description = "SSH command to access the VM"
  value       = module.database.ssh_command
}

# -------------------------
# MySQL connection string
# -------------------------
output "mysql_connection_string" {
  description = "MySQL connection string"
  sensitive   = true
  value       = module.database.mysql_connection_string
}

output "app_vm_public_ip" {
  description = "Public IP of the application VM"
  value       = module.application.app_vm_public_ip
}

output "app_url" {
  description = "URL to access the API documentation"
  value       = module.application.app_url
}

output "ssh_command_for_app" {
  description = "SSH command to connect to the VM"
  value       = module.application.ssh_command
}