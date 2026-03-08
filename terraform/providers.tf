terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "storblobexam123"
    container_name       = "terraform-state"
    key                  = "dev.terraform.tfstate"
  }

  required_version = "~>1.14.0"
}

provider "azurerm" {
  features {}
}