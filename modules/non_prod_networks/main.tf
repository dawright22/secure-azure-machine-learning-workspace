# Create three virtual networks
resource "azurerm_virtual_network" "vnet" {
  count = var.number_of_networks

  name                = "${var.name}-non-prod-${count.index}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = ["10.1.${count.index}.0/24"]
}

# Add a subnet to each virtual network

resource "azurerm_subnet" "subnet_vnet" {
  count = var.number_of_networks

  name                 = "non-prod-subnet-${count.index}"
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  resource_group_name  = var.resource_group_name
  address_prefixes     = ["10.1.${count.index}.0/24"]
}