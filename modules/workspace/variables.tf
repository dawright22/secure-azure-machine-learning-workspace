
variable "resource_group_location" {
  description = "Location of the resource group."
}

variable "resource_group_name" {
  description = "Name of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "name" {
  description = "Name of the resources"
}

variable "hub_vnet_id" {
    description = "hub vnet id"
}

# DSVM
variable "dsvm_name" {
  type        = string
  description = "Name of the Data Science VM"
  default     = "vmdsvm01"
}

variable "dsvm_admin_username" {
  type        = string
  description = "Admin username of the Data Science VM"
  default     = "azureadmin"
}

variable "dsvm_host_password" {
  type        = string
  description = "Password for the admin username of the Data Science VM"
  sensitive   = true
}

#Image Build Compute
variable "image_build_compute_name" {
  type        = string
  description = "Name of the compute cluster to be created and set to build docker images"
  default     = "image-builder"
}

