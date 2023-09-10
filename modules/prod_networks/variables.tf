variable "resource_group_location" {
  description = "Location of the resource group."
}

variable "resource_group_name" {
  description = "Name of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "name" {
  description = "Name of the resources"
}

variable "number_of_networks" {
  description = "Number of resources to create"
}