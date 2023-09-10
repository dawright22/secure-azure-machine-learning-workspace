
//create Hub Vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name}-hub-vnet"
  address_space       = ["192.168.0.0/16"]
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}


//Create Azure Bation Host
resource "azurerm_subnet" "bastion-subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_public_ip" "bastion-pip" {
  name                = "${var.name}-bastion-pip"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion-host" {
  name                = "${var.name}-bastion"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
}

//create Azure Firewall
resource "azurerm_subnet" "FWsubnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.2.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.name}-fw-pip"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "main" {
  name                = "${var.name}-fw"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.FWsubnet.id
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_firewall_application_rule_collection" "app-rc" {
  name                = "${var.name}-fw-app-rc"
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  rule {
    name = "testrule"

    source_addresses = [
      "192.168.0.0/16",
    ]

    target_fqdns = [
      "*.microsoft.com",
    ]

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "net-rc" {
  name                = "${var.name}-fw-net-rc"
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  rule {
    name = "dnsrule"

    source_addresses = [
      "192.168.0.0/16",
    ]

    destination_ports = [
      "53",
    ]

    destination_addresses = [
      "8.8.8.8",
      "8.8.4.4",
    ]

    protocols = [
      "TCP",
      "UDP",
    ]
  }
}

# Create Azure Virtual Network Gateway

resource "azurerm_subnet" "hub-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.3.0/24"]
}

resource "azurerm_public_ip" "hub-vpn-gateway1-pip" {
    name                = "${var.name}-gateway1-pip"
    location            = var.resource_group_location
    resource_group_name = var.resource_group_name

    allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "hub-vnet-gateway" {
    name                = "${var.name}-hub-vpn-gateway1"
    location            = var.resource_group_location
    resource_group_name = var.resource_group_name

    type     = "Vpn"
    vpn_type = "RouteBased"

    active_active = false
    enable_bgp    = false
    sku           = "VpnGw1"

    ip_configuration {
    name                          = "${var.name}-vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.hub-vpn-gateway1-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub-gateway-subnet.id
    }
    depends_on = [azurerm_public_ip.hub-vpn-gateway1-pip]
}

