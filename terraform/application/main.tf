# Data sources to reference existing resources from database module
data "azurerm_resource_group" "existing_db_rg" {
  name = "rg-mysql-dev"
}

data "azurerm_virtual_network" "existing_vnet" {
  name                = "vnet-mysql-dev"
  resource_group_name = data.azurerm_resource_group.existing_db_rg.name
}

data "azurerm_subnet" "existing_subnet" {
  name                 = "snet-mysql-vm"
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name  = data.azurerm_resource_group.existing_db_rg.name
}

# Public IP for app VM
resource "azurerm_public_ip" "app_vm_pip" {
  name                = "pip-app-vm"
  location            = data.azurerm_resource_group.existing_db_rg.location
  resource_group_name = data.azurerm_resource_group.existing_db_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Security Group for app VM
resource "azurerm_network_security_group" "app_vm_nsg" {
  name                = "nsg-app-vm"
  location            = data.azurerm_resource_group.existing_db_rg.location
  resource_group_name = data.azurerm_resource_group.existing_db_rg.name

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
    name                       = "API"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Data source to get public IP
data "http" "myip" {
  url = "https://api.ipify.org"
}

# Network Interface for app VM
resource "azurerm_network_interface" "app_vm_nic" {
  name                = "nic-app-vm"
  location            = data.azurerm_resource_group.existing_db_rg.location
  resource_group_name = data.azurerm_resource_group.existing_db_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.existing_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app_vm_pip.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "app_vm_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.app_vm_nic.id
  network_security_group_id = azurerm_network_security_group.app_vm_nsg.id
}

# MySQL VM private IP (hardcoded as it's static)
locals {
  mysql_private_ip = "10.0.1.4"
  app_port         = 8000
}

# Linux VM for the Application
resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "vm-app-minimal"
  resource_group_name = data.azurerm_resource_group.existing_db_rg.name
  location            = data.azurerm_resource_group.existing_db_rg.location
  size                = "Standard_D2ls_v5"

  admin_username = "azureuser"
  
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.app_vm_nic.id
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

  # Cloud-init using UV
  custom_data = base64encode(<<-EOF
    #cloud-config
    package_update: true
    packages:
      - curl
      - git
      - python3-pip
    runcmd:
      - sudo apt update
      - sudo apt install -y git
      # Install UV (uses default PATH for root: /root/.cargo/bin)
      - pip install uv
      
      # Clone repository
      - cd /opt
      - git clone https://github.com/FernandoFdezdC/prueba_tecnica_globant.git app
      - cd /opt/src

      # Use uv
      - uv python install 3.12
      - uv venv --python 3.12
      # Activate virtual environment
      - source .venv/bin/activate  # On Unix/macOS

      - uv pip install -r requirements.txt
      
      # Install dependencies with UV (using --system to install globally)
      - uv pip install --system fastapi uvicorn gunicorn python-dotenv mysql-connector-python
      
      # Verify that gunicorn is installed
      - which gunicorn || (echo "Gunicorn not installed" && exit 1)
      
      # Start the application
      - cd /opt/app/src
      - nohup gunicorn main:app --bind 0.0.0.0:${local.app_port} -k uvicorn.workers.UvicornWorker > /var/log/app.log 2>&1 &
      
      # Create startup script
      - echo '#!/bin/bash' > /opt/start-app.sh
      - echo 'cd /opt/app/src' >> /opt/start-app.sh
      - echo 'gunicorn main:app --bind 0.0.0.0:${local.app_port} -k uvicorn.workers.UvicornWorker' >> /opt/start-app.sh
      - chmod +x /opt/start-app.sh
      
      # Wait and verify
      - sleep 10
      - curl -f http://localhost:${local.app_port}/docs || echo "App started, health check failed - check logs at /var/log/app.log"
  EOF
  )
}