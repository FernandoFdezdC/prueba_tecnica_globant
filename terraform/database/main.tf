# -------------------------
# Resource Group
# -------------------------
resource "azurerm_resource_group" "db" {
  name     = "rg-mysql-dev"
  location = "Canada Central"
}

# -------------------------
# Virtual Network
# -------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-mysql-dev"
  location            = azurerm_resource_group.db.location
  resource_group_name = azurerm_resource_group.db.name
  address_space       = ["10.0.0.0/16"]
}

# -------------------------
# Subnet
# -------------------------
resource "azurerm_subnet" "vm_subnet" {
  name                 = "snet-mysql-vm"
  resource_group_name  = azurerm_resource_group.db.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# -------------------------
# Public IP
# -------------------------
resource "azurerm_public_ip" "mysql_vm_pip" {
  name                = "pip-mysql-vm"
  location            = azurerm_resource_group.db.location
  resource_group_name = azurerm_resource_group.db.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# -------------------------
# Network Security Group
# -------------------------
resource "azurerm_network_security_group" "mysql_vm_nsg" {
  name                = "nsg-mysql-vm"
  location            = azurerm_resource_group.db.location
  resource_group_name = azurerm_resource_group.db.name

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${chomp(data.http.myip.response_body)}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "MySQL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.0.0.0/16"   # Allow connections from within the VNet
    destination_address_prefix = "*"
  }
}

# -------------------------
# Data source to get public IP
# -------------------------
data "http" "myip" {
  url = "https://api.ipify.org"
}

# -------------------------
# Network Interface
# -------------------------
resource "azurerm_network_interface" "mysql_vm_nic" {
  name                = "nic-mysql-vm"
  location            = azurerm_resource_group.db.location
  resource_group_name = azurerm_resource_group.db.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mysql_vm_pip.id
  }
}

# -------------------------
# Associate NSG with NIC
# -------------------------
resource "azurerm_network_interface_security_group_association" "mysql_vm_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.mysql_vm_nic.id
  network_security_group_id = azurerm_network_security_group.mysql_vm_nsg.id
}

# -------------------------
# Linux VM with MySQL
# -------------------------
resource "azurerm_linux_virtual_machine" "mysql_vm" {
  name                = "vm-mysql-minimal"
  resource_group_name = azurerm_resource_group.db.name
  location            = azurerm_resource_group.db.location
  size                = "Standard_D2ls_v5"

  admin_username = "azureuser"
  
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.mysql_vm_nic.id
  ]

  os_disk {
    caching              = "ReadOnly"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "minimal"
    version   = "latest"
  }

  # Cloud-init: install MySQL, set root password, and enable remote connections
  custom_data = base64encode(<<-EOF
    #cloud-config
    package_update: true
    packages:
      - mysql-server
      - mysql-client
    runcmd:
      # Start MySQL and wait for it to be ready
      - systemctl enable mysql
      - systemctl start mysql
      - while ! mysqladmin ping -h localhost --silent; do sleep 2; done
      # Set root password
      - mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${var.mysql_password}'; FLUSH PRIVILEGES;"
      # Allow remote connections (bind-address)
      - echo "bind-address = 0.0.0.0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
      # Restart to apply changes
      - systemctl restart mysql
  EOF
  )

  tags = {
    environment = "dev"
    service     = "mysql"
  }

  # Connection info for provisioners
  connection {
    type        = "ssh"
    host        = azurerm_linux_virtual_machine.mysql_vm.public_ip_address
    user        = "azureuser"
    private_key = file("~/.ssh/id_rsa")
    timeout     = "5m"
  }

  # Create directory for SQL files
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/init-db"
    ]
  }

  # Copy SQL files from local ./init-db/ directory to the VM
  provisioner "file" {
    source      = "${path.module}/init-db/01-schema.sql"
    destination = "/tmp/init-db/01-schema.sql"
  }

  # We're NOT copying 02-user.sql - we'll execute commands directly
  provisioner "file" {
    source      = "${path.module}/init-db/03-tables.sql"
    destination = "/tmp/init-db/03-tables.sql"
  }

  provisioner "file" {
    source      = "${path.module}/init-db/04-indexes.sql"
    destination = "/tmp/init-db/04-indexes.sql"
  }

  # Execute SQL files and direct commands in order
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for MySQL to be ready with password...'",
      "until sudo mysql -u root -p${var.mysql_password} -e 'SELECT 1' >/dev/null 2>&1; do echo 'Waiting...'; sleep 5; done",
      "echo 'MySQL is ready.'",
      
      "echo 'Running 01-schema.sql...'",
      "sudo mysql -u root -p${var.mysql_password} < /tmp/init-db/01-schema.sql",
      
      "echo 'Configuring root users directly...'",
      "sudo mysql -u root -p${var.mysql_password} -e \"CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${var.mysql_password}';\"",
      "sudo mysql -u root -p${var.mysql_password} -e \"GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;\"",
      "sudo mysql -u root -p${var.mysql_password} -e \"FLUSH PRIVILEGES;\"",
      "sudo mysql -u root -p${var.mysql_password} -e \"DROP USER IF EXISTS 'root'@'localhost';\"",
      "sudo mysql -u root -p${var.mysql_password} -e \"FLUSH PRIVILEGES;\"",
      
      "echo 'Running 03-tables.sql...'",
      "sudo mysql -u root -p${var.mysql_password} db_migration_ddbb < /tmp/init-db/03-tables.sql",
      
      "echo 'Running 04-indexes.sql...'",
      "sudo mysql -u root -p${var.mysql_password} db_migration_ddbb < /tmp/init-db/04-indexes.sql",
      
      "echo 'All SQL files executed.'",
      "echo 'Verification:'",
      "sudo mysql -u root -p${var.mysql_password} -e 'SHOW DATABASES;'",
      "sudo mysql -u root -p${var.mysql_password} db_migration_ddbb -e 'SHOW TABLES;'",
      "sudo mysql -u root -p${var.mysql_password} -e 'SELECT user, host FROM mysql.user;'"
    ]
  }
}