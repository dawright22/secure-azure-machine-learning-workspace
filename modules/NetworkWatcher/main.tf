# Log collection components
resource "azurerm_storage_account" "network_log_data" {
  name                      = "networklogdatawathcer"
  resource_group_name       = var.resource_group_name
  location                  = var.resource_group_location
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  min_tls_version           = "TLS1_2"
}

resource "azurerm_log_analytics_workspace" "traffic_analytics" {
  name                = "prod-traffic-analytics"
  resource_group_name       = var.resource_group_name
  location                  = var.resource_group_location
  retention_in_days   = 90
  daily_quota_gb      = 10
}

resource "azurerm_network_security_group" "flow_log_nsg" {
  name                      = "${var.name}-nsg"
  resource_group_name       = var.resource_group_name
  location                  = var.resource_group_location
}
# The Network Watcher Instance & network log flow
# There can only be one Network Watcher per subscription and region


resource "azurerm_network_watcher" "HubAndSpoke_traffic" {
  name                      = "${var.name}-NetworkWatcher"
  resource_group_name       = var.resource_group_name
  location                  = var.resource_group_location
}

resource "azurerm_network_watcher_flow_log" "HubAndSpoke_network_logs" {
  network_watcher_name = azurerm_network_watcher.HubAndSpoke_traffic.name
  resource_group_name  = var.resource_group_name
  name = "${var.name}-network-log"

  network_security_group_id = azurerm_network_security_group.flow_log_nsg.id
  storage_account_id        = azurerm_storage_account.network_log_data.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 90
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.traffic_analytics.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.traffic_analytics.location
    workspace_resource_id = azurerm_log_analytics_workspace.traffic_analytics.id
    interval_in_minutes   = 10
  }
}