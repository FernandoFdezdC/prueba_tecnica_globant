# -------------------------
# Resource Group
# -------------------------
resource "azurerm_resource_group" "db" {
  name     = "rg-mysql-dev"
  location = "East US"
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
# Subnet for Private Endpoint
# -------------------------
resource "azurerm_subnet" "mysql_subnet" {
  name                 = "snet-mysql"
  resource_group_name  = azurerm_resource_group.db.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  # Needed for MySQL flexible server private access
  delegation {
    name = "mysql_delegation"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# -------------------------
# MySQL Flexible Server (Private Network)
# -------------------------
resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "mysql-minimal-01"
  resource_group_name = azurerm_resource_group.db.name
  location            = azurerm_resource_group.db.location

  administrator_login    = "mysqladmin"
  administrator_password = var.mysql_password

  version = "8.0.21"

  sku_name = "B_Standard_B1ms" # supported minimal SKU

  storage {
    size_gb = 20
  }

  backup_retention_days = 7

  # Configure Private Network
  delegated_subnet_id = azurerm_subnet.mysql_subnet.id
}

# -------------------------
# MySQL Database
# -------------------------
resource "azurerm_mysql_flexible_database" "appdb" {
  name                = "app_database"
  resource_group_name = azurerm_resource_group.db.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}