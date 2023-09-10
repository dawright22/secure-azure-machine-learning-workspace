# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.66.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}


provider "azurerm" {
  features {}
}

resource "random_pet" "name" {
  prefix = var.resource_group_name_prefix
  length = 1
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


######################################
# Create Resource Group.
######################################

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "${random_pet.name.id}.rg"
}

######################################
# Create hub networks
######################################

module "hub_spoke_network" {
  source                  = "./modules/hub_network"
  name                    = random_pet.name.id
  resource_group_location = var.resource_group_location
  resource_group_name     = azurerm_resource_group.rg.name
}


######################################
# Create prod spoke networks
######################################

module "prod_spoke_networks" {
  number_of_networks      = 2
  source                  = "./modules/prod_networks"
  name                    = random_pet.name.id
  resource_group_location = var.resource_group_location
  resource_group_name     = azurerm_resource_group.rg.name
}

######################################
# Create prod spoke networks
######################################

module "non_prod_spoke_networks" {
  number_of_networks      = 2
  source                  = "./modules/non_prod_networks"
  name                    = random_pet.name.id
  resource_group_location = var.resource_group_location
  resource_group_name     = azurerm_resource_group.rg.name
}

######################################
# Create a Networks Manager to Control all the traffic
######################################
module "NetworkManager" {
  source                  = "./modules/NetworkManager"
  name                    = random_pet.name.id
  resource_group_location = var.resource_group_location
  resource_group_name     = azurerm_resource_group.rg.name
  hub_vnet_id             = module.hub_spoke_network.vnet_id
}

######################################
# Create Azure Monitoring
######################################

module "NetworkWatcher" {
  source                  = "./modules/NetworkWatcher"
  name                    = random_pet.name.id
  resource_group_location = var.resource_group_location
  resource_group_name     = azurerm_resource_group.rg.name
}

######################################
# Create Azure Machine Learning Workspace
######################################

module "workspace" {
  source                  = "./modules/workspace"
  name                    = random_pet.name.id
  resource_group_location = var.resource_group_location
  resource_group_name     = azurerm_resource_group.rg.name
  dsvm_host_password      = random_password.password.result
  hub_vnet_id             = module.hub_spoke_network.vnet_id
}
