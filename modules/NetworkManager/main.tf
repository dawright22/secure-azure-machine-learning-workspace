# Create a Virtual Network Manager instance

data "azurerm_subscription" "current" {
}

resource "azurerm_network_manager" "network_manager_instance" {
  name                = "HubandSpoke-network-manager"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  scope_accesses      = ["Connectivity"]
  description         = "Azure network manager"
  scope {
    subscription_ids = [data.azurerm_subscription.current.id]
  }
}

# Create a Production network group

resource "azurerm_network_manager_network_group" "network_group" {
  name               = "prod-network-group"
  network_manager_id = azurerm_network_manager.network_manager_instance.id
}

# Add virtual networks to a network group as dynamic members with Azure Policy


resource "azurerm_policy_definition" "network_group_policy" {
  name         = "${var.name}-prod-policy"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "Policy Definition for Network Group"

  metadata = <<METADATA
    {
      "category": "Azure Virtual Network Manager"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
      "if": {
        "allOf": [
          {
              "field": "type",
              "equals": "Microsoft.Network/virtualNetworks"
          },
          {
            "allOf": [
              {
              "field": "Name",
              "contains": "${var.name}-prod"
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "addToNetworkGroup",
        "details": {
          "networkGroupId": "${azurerm_network_manager_network_group.network_group.id}"
        }
      }
    }
  POLICY_RULE
}

resource "azurerm_subscription_policy_assignment" "azure_policy_assignment" {
  name                 = "${var.name}-prod-policy-assignment"
  policy_definition_id = azurerm_policy_definition.network_group_policy.id
  subscription_id      = data.azurerm_subscription.current.id
}

# Create a connectivity configuration

resource "azurerm_network_manager_connectivity_configuration" "connectivity_config" {
  name                  = "connectivity-config-prod"
  network_manager_id    = azurerm_network_manager.network_manager_instance.id
  connectivity_topology = "HubAndSpoke"
  applies_to_group {
    group_connectivity = "DirectlyConnected"
    network_group_id   = azurerm_network_manager_network_group.network_group.id
    use_hub_gateway = true
  }
    hub {
    resource_id   = var.hub_vnet_id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
  delete_existing_peering_enabled = false
}

# Create a non production network group

resource "azurerm_network_manager_network_group" "network_group_non_prod" {
  name               = "non-prod-network-group"
  network_manager_id = azurerm_network_manager.network_manager_instance.id
}

# Add three virtual networks to a network group as dynamic members with Azure Policy


resource "azurerm_policy_definition" "network_group_policy_non_prod" {
  name         = "${var.name}-non-prod-policy"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "Policy Definition for Network Group"

  metadata = <<METADATA
    {
      "category": "Azure Virtual Network Manager"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
      "if": {
        "allOf": [
          {
              "field": "type",
              "equals": "Microsoft.Network/virtualNetworks"
          },
          {
            "allOf": [
              {
              "field": "Name",
              "contains": "${var.name}-non-prod"
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "addToNetworkGroup",
        "details": {
          "networkGroupId": "${azurerm_network_manager_network_group.network_group_non_prod.id}"
        }
      }
    }
  POLICY_RULE
}

resource "azurerm_subscription_policy_assignment" "azure_policy_assignment_non_prod" {
  name                 = "${var.name}-non-prod-policy-assignment"
  policy_definition_id = azurerm_policy_definition.network_group_policy_non_prod.id
  subscription_id      = data.azurerm_subscription.current.id
}

# Create a connectivity configuration

resource "azurerm_network_manager_connectivity_configuration" "connectivity_config_non_prod" {
  name                  = "connectivity-config-non-prod"
  network_manager_id    = azurerm_network_manager.network_manager_instance.id
  connectivity_topology = "HubAndSpoke"
  applies_to_group {
    group_connectivity = "DirectlyConnected"
    network_group_id   = azurerm_network_manager_network_group.network_group_non_prod.id
    use_hub_gateway = true
  }
    hub {
    resource_id   = var.hub_vnet_id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
  delete_existing_peering_enabled = false
}


# Commit deployment

resource "azurerm_network_manager_deployment" "commit_deployment_non_prod" {
  network_manager_id = azurerm_network_manager.network_manager_instance.id
  location           = var.resource_group_location
  scope_access       = "Connectivity"
  configuration_ids  = [azurerm_network_manager_connectivity_configuration.connectivity_config_non_prod.id, azurerm_network_manager_connectivity_configuration.connectivity_config.id]
}