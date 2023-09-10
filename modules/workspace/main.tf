data "azurerm_client_config" "current" {}

# Private DNS Zones
resource "azurerm_private_dns_zone" "dnsvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnetlinkvault" {
  name                  = "dnsvaultlink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnsvault.name
  virtual_network_id    = var.hub_vnet_id
}

resource "azurerm_private_dns_zone" "dnsstorageblob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnetlinkblob" {
  name                  = "dnsblobstoragelink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnsstorageblob.name
  virtual_network_id    = var.hub_vnet_id
}

resource "azurerm_private_dns_zone" "dnsstoragefile" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnetlinkfile" {
  name                  = "dnsfilestoragelink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnsstoragefile.name
  virtual_network_id    = var.hub_vnet_id
}

resource "azurerm_private_dns_zone" "dnscontainerregistry" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnetlinkcr" {
  name                  = "dnscrlink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnscontainerregistry.name
  virtual_network_id    = var.hub_vnet_id
}

resource "azurerm_private_dns_zone" "dnsazureml" {
  name                = "privatelink.api.azureml.ms"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnetlinkml" {
  name                  = "dnsazuremllink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnsazureml.name
  virtual_network_id    = var.hub_vnet_id
}

resource "azurerm_private_dns_zone" "dnsnotebooks" {
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnetlinknbs" {
  name                  = "dnsnotebookslink"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnsnotebooks.name
  virtual_network_id    = var.hub_vnet_id
}

resource "azurerm_network_interface" "dsvm" {
  name                = "nic-${var.name}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = azurerm_subnet.hub-subnet-workspace.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_subnet" "hub-subnet-workspace" {
  name                                           = "${var.name}hub-subnet-workspace"
  resource_group_name                            = var.resource_group_name
  virtual_network_name                           = var.hub_vnet_id
  address_prefixes                               = ["192.168.4.0/24"]
  private_endpoint_network_policies_enabled      = true
}

resource "azurerm_windows_virtual_machine" "dsvm" {
  name                = "dsvm-${var.name}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  network_interface_ids = [
    azurerm_network_interface.dsvm.id
  ]
  size = "Standard_DS3_v2"

  source_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "dsvm-win-2019"
    sku       = "server-2019"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-${var.name}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  identity {
    type = "SystemAssigned"
  }
  computer_name  = var.dsvm_name
  admin_username = var.dsvm_admin_username
  admin_password = var.dsvm_host_password

  provision_vm_agent = true

  timeouts {
    create = "60m"
    delete = "2h"
  }
}

# Dependent resources for Azure Machine Learning
resource "azurerm_log_analytics_workspace" "azureml-workspace" {
  name                = "log-workspace-ai-${var.name}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "default" {
  name                = "appi-insights-ai-${var.name}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.azureml-workspace.id
  application_type    = "web"
}

resource "azurerm_key_vault" "default" {
  name                     = "ai-key-vault-${var.name}"
  location                 = var.resource_group_location
  resource_group_name      = var.resource_group_name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "premium"
  purge_protection_enabled = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_storage_account" "default" {
  name                            = "storageaccountai"
  location                        = var.resource_group_location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  allow_nested_items_to_be_public = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_container_registry" "default" {
  name                = "containerRegistryAI"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku                 = "Premium"
  admin_enabled       = true

  network_rule_set {
    default_action = "Deny"
  }
  public_network_access_enabled = false
}

# Machine Learning workspace
resource "azurerm_machine_learning_workspace" "default" {
  name                    = "mlw-${var.name}-AI-workspace"
  location                = var.resource_group_location
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.default.id
  key_vault_id            = azurerm_key_vault.default.id
  storage_account_id      = azurerm_storage_account.default.id
  container_registry_id   = azurerm_container_registry.default.id

  identity {
    type = "SystemAssigned"
  }
  public_network_access_enabled = false
  image_build_compute_name      = var.image_build_compute_name
}

# Private endpoints
resource "azurerm_private_endpoint" "kv_ple" {
  name                = "ple-${var.name}-AI-endpoint-kv"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.hub-subnet-workspace.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsvault.id] //this need to change
  }

  private_service_connection {
    name                           = "psc-${var.name}-kv"
    private_connection_resource_id = azurerm_key_vault.default.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "st_ple_blob" {
  name                = "ple-${var.name}-AI-st-blob"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.hub-subnet-workspace.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsstorageblob.id] //this  need to change
  }

  private_service_connection {
    name                           = "psc-${var.name}-st"
    private_connection_resource_id = azurerm_storage_account.default.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "storage_ple_file" {
  name                = "ple-${var.name}-AI-st-file"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.hub-subnet-workspace.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsstoragefile.id] //this need to change
  }

  private_service_connection {
    name                           = "psc-${var.name}-st"
    private_connection_resource_id = azurerm_storage_account.default.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "cr_ple" {
  name                = "ple-${var.name}-AI-cr"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.hub-subnet-workspace.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnscontainerregistry.id] //this need to change
  }

  private_service_connection {
    name                           = "psc-${var.name}-cr"
    private_connection_resource_id = azurerm_container_registry.default.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "mlw_ple" {
  name                = "ple-${var.name}-AI-mlw"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.hub-subnet-workspace.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsazureml.id, azurerm_private_dns_zone.dnsnotebooks.id] //this need to change
  }

  private_service_connection {
    name                           = "psc-${var.name}-mlw"
    private_connection_resource_id = azurerm_machine_learning_workspace.default.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }
}

# Compute cluster for image building required since the workspace is behind a vnet.
# For more details, see https://docs.microsoft.com/en-us/azure/machine-learning/tutorial-create-secure-workspace#configure-image-builds.
resource "azurerm_machine_learning_compute_cluster" "image-builder" {
  name                          = var.image_build_compute_name
  location                      = var.resource_group_location
  vm_priority                   = "LowPriority"
  vm_size                       = "Standard_DS2_v2"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.default.id
  subnet_resource_id            = azurerm_subnet.hub-subnet-workspace.id

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 3
    scale_down_nodes_after_idle_duration = "PT15M" # 15 minutes
  }

  identity {
    type = "SystemAssigned"
  }
  depends_on = [
    azurerm_private_endpoint.mlw_ple
  ]
}
