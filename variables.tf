##############################################################################
# Variables File
# 
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)

variable "resource_group_location" {
  default     = "Australia East"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  default     = "tf"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}