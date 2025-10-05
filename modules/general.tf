#================================================
# GENERAL SERVICES
#================================================

# Logic Apps for workflow automation
resource "azurerm_logic_app_workflow" "main" {
  count               = var.enable_logic_apps ? 1 : 0
  name                = "logic-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name

  tags = local.common_tags
}

# Automation Account
resource "azurerm_automation_account" "main" {
  count               = var.enable_automation ? 1 : 0
  name                = "aa-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku_name            = "Basic"

  # Security settings
  public_network_access_enabled = false

  tags = local.common_tags
}

# Service Bus Namespace for general messaging
resource "azurerm_servicebus_namespace" "general" {
  count               = var.enable_service_bus ? 1 : 0
  name                = "sb-${local.resource_prefix}-general-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  sku                 = "Standard"

  # Security settings
  public_network_access_enabled = false

  tags = local.common_tags
}

# API Management
resource "azurerm_api_management" "main" {
  count               = var.enable_api_management ? 1 : 0
  name                = "apim-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  publisher_name      = var.api_management_publisher_name
  publisher_email     = var.api_management_publisher_email
  sku_name            = var.api_management_sku

  # Security settings
  public_network_access_enabled = false
  virtual_network_type          = "Internal"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.spoke_alpha_workload[0].id
  }

  tags = local.common_tags
}

# Notification Hub Namespace
resource "azurerm_notification_hub_namespace" "main" {
  count               = var.enable_notification_hub ? 1 : 0
  name                = "ntfns-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  namespace_type      = "NotificationHub"
  sku_name            = "Free"

  tags = local.common_tags
}

# Notification Hub
resource "azurerm_notification_hub" "main" {
  count               = var.enable_notification_hub ? 1 : 0
  name                = "ntf-${local.resource_prefix}-main"
  namespace_name      = azurerm_notification_hub_namespace.main[0].name
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
}

# Search Service
resource "azurerm_search_service" "main" {
  count                         = var.enable_search_service ? 1 : 0
  name                          = "srch-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name           = azurerm_resource_group.spokes[0].name
  location                      = azurerm_resource_group.spokes[0].location
  sku                          = var.search_service_sku
  replica_count                = 1
  partition_count              = 1
  public_network_access_enabled = false

  tags = local.common_tags
}

# Private Endpoints for General Services
resource "azurerm_private_endpoint" "automation" {
  count               = var.enable_automation ? 1 : 0
  name                = "pep-${local.resource_prefix}-aa-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  subnet_id           = azurerm_subnet.hub_private_endpoint.id

  private_service_connection {
    name                           = "psc-automation"
    private_connection_resource_id = azurerm_automation_account.main[0].id
    subresource_names              = ["DSCAndHybridWorker"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "service_bus_general" {
  count               = var.enable_service_bus ? 1 : 0
  name                = "pep-${local.resource_prefix}-sb-general-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-service-bus-general"
    private_connection_resource_id = azurerm_servicebus_namespace.general[0].id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "search_service" {
  count               = var.enable_search_service ? 1 : 0
  name                = "pep-${local.resource_prefix}-srch-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-search-service"
    private_connection_resource_id = azurerm_search_service.main[0].id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}
