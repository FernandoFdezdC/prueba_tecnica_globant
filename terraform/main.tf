module "database" {
  source         = "./database"
  mysql_password = var.mysql_password
}

module "application" {
  source         = "./application"
  mysql_password = var.mysql_password
}