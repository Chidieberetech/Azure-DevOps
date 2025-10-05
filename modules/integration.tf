#================================================
# INTEGRATION SERVICES
#================================================

# Service Bus Namespace for enterprise messaging
resource "azurerm_servicebus_namespace" "integration" {
  count               = var.enable_integration_servicebus ? 1 : 0
  name                = "sb-${local.resource_prefix}-int-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  sku                 = "Premium"
  capacity            = 1

  # Security settings
  public_network_access_enabled = false

  tags = local.common_tags
}

# Event Grid System Topic
resource "azurerm_eventgrid_system_topic" "main" {
  count                  = var.enable_event_grid ? 1 : 0
  name                   = "evgt-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name    = azurerm_resource_group.spokes[0].name
  location               = azurerm_resource_group.spokes[0].location
  source_arm_resource_id = azurerm_storage_account.main.id
  topic_type             = "Microsoft.Storage.StorageAccounts"

  tags = local.common_tags
}

# Event Grid Custom Topic
resource "azurerm_eventgrid_topic" "custom" {
  count               = var.enable_event_grid ? 1 : 0
  name                = "evgt-${local.resource_prefix}-custom-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name

  # Security settings
  public_network_access_enabled = false

  tags = local.common_tags
}

# Logic App for workflow integration
resource "azurerm_logic_app_workflow" "integration" {
  count               = var.enable_integration_logic_apps ? 1 : 0
  name                = "logic-${local.resource_prefix}-int-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name

  tags = local.common_tags
}

# API Connections for Logic Apps
resource "azurerm_logic_app_action_custom" "integration_action" {
  count        = var.enable_integration_logic_apps ? 1 : 0
  name         = "integration-action"
  logic_app_id = azurerm_logic_app_workflow.integration[0].id

  body = jsonencode({
    definition = {
      type = "Http"
      inputs = {
        method = "GET"
        uri    = "https://api.example.com/integration"
      }
    }
  })
}

# Application Gateway for API integration
resource "azurerm_application_gateway" "integration" {
  count               = var.enable_app_gateway ? 1 : 0
  name                = "agw-${local.resource_prefix}-int-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location

  sku {
    name     = var.app_gateway_sku_name
    tier     = var.app_gateway_sku_tier
    capacity = var.app_gateway_capacity
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.spoke_alpha_workload[0].id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGwPrivateFrontendIp"
    private_ip_address_allocation = "Dynamic"
    subnet_id           = azurerm_subnet.spoke_alpha_workload[0].id
  }

  backend_address_pool {
    name = "appGwBackendPool"
  }

  backend_http_settings {
    name                  = "appGwBackendHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "appGwHttpListener"
    frontend_ip_configuration_name = "appGwPrivateFrontendIp"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "appGwRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "appGwHttpListener"
    backend_address_pool_name  = "appGwBackendPool"
    backend_http_settings_name = "appGwBackendHttpSettings"
    priority                   = 100
  }

  tags = local.common_tags
}

# Relay Namespace for hybrid connections
resource "azurerm_relay_namespace" "main" {
  count               = var.enable_relay ? 1 : 0
  name                = "rly-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  sku_name            = "Standard"

  tags = local.common_tags
}

# Relay Hybrid Connection
resource "azurerm_relay_hybrid_connection" "main" {
  count                = var.enable_relay ? 1 : 0
  name                 = "rhc-main"
  resource_group_name  = azurerm_resource_group.spokes[0].name
  relay_namespace_name = azurerm_relay_namespace.main[0].name
  user_metadata        = "Integration hybrid connection"
}

# Private Endpoints for Integration Services
resource "azurerm_private_endpoint" "integration_servicebus" {
  count               = var.enable_integration_servicebus ? 1 : 0
  name                = "pep-${local.resource_prefix}-sb-int-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-integration-servicebus"
    private_connection_resource_id = azurerm_servicebus_namespace.integration[0].id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "eventgrid_topic" {
  count               = var.enable_event_grid ? 1 : 0
  name                = "pep-${local.resource_prefix}-evgt-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-eventgrid-topic"
    private_connection_resource_id = azurerm_eventgrid_topic.custom[0].id
    subresource_names              = ["topic"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}
