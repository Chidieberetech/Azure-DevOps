#================================================
# DEVOPS SERVICES
#================================================

# Container Registry for DevOps artifacts
resource "azurerm_container_registry" "devops" {
  count               = var.enable_devops ? 1 : 0
  name                = "acr${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}devops${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sku                 = "Premium"
  admin_enabled       = false

  # Security settings
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"

  tags = local.common_tags
}

# Storage Account for DevOps artifacts
resource "azurerm_storage_account" "devops" {
  count                    = var.enable_devops ? 1 : 0
  name                     = "st${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}devops${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.spokes[0].name
  location                 = azurerm_resource_group.spokes[0].location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security settings
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  tags = local.common_tags
}

# Key Vault for DevOps secrets
resource "azurerm_key_vault" "devops" {
  count                      = var.enable_devops ? 1 : 0
  name                       = "kv-${local.resource_prefix}-devops-${format("%03d", 1)}"
  location                   = azurerm_resource_group.spokes[0].location
  resource_group_name        = azurerm_resource_group.spokes[0].name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Security settings
  public_network_access_enabled = false
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.common_tags
}

# Application Configuration for feature flags
resource "azurerm_app_configuration" "devops" {
  count               = var.enable_devops ? 1 : 0
  name                = "appcs-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sku                 = "standard"

  # Security settings
  public_network_access_enabled = false

  tags = local.common_tags
}

# Service Bus for DevOps messaging
resource "azurerm_servicebus_namespace" "devops" {
  count               = var.enable_devops ? 1 : 0
  name                = "sb-${local.resource_prefix}-devops-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  sku                 = "Standard"

  tags = local.common_tags
}

# Service Bus Queue for build notifications
resource "azurerm_servicebus_queue" "build_notifications" {
  count        = var.enable_devops ? 1 : 0
  name         = "build-notifications"
  namespace_id = azurerm_servicebus_namespace.devops[0].id
}

# Private Endpoints for DevOps Services
resource "azurerm_private_endpoint" "devops_acr" {
  count               = var.enable_devops ? 1 : 0
  name                = "pep-${local.resource_prefix}-devops-acr-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-devops-acr"
    private_connection_resource_id = azurerm_container_registry.devops[0].id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "devops_storage" {
  count               = var.enable_devops ? 1 : 0
  name                = "pep-${local.resource_prefix}-devops-st-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-devops-storage"
    private_connection_resource_id = azurerm_storage_account.devops[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "devops_keyvault" {
  count               = var.enable_devops ? 1 : 0
  name                = "pep-${local.resource_prefix}-devops-kv-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-devops-keyvault"
    private_connection_resource_id = azurerm_key_vault.devops[0].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "app_configuration" {
  count               = var.enable_devops ? 1 : 0
  name                = "pep-${local.resource_prefix}-appcs-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-app-configuration"
    private_connection_resource_id = azurerm_app_configuration.devops[0].id
    subresource_names              = ["configurationStores"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "servicebus" {
  count               = var.enable_devops ? 1 : 0
  name                = "pep-${local.resource_prefix}-sb-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-servicebus"
    private_connection_resource_id = azurerm_servicebus_namespace.devops[0].id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}
