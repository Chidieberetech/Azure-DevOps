#================================================
# AI + MACHINE LEARNING SERVICES
#================================================

# Cognitive Services Account
resource "azurerm_cognitive_account" "main" {
  count               = var.enable_cognitive_services ? 1 : 0
  name                = "cog-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  kind                = "CognitiveServices"
  sku_name            = var.cognitive_services_sku

  # Security settings
  public_network_access_enabled = false
  custom_subdomain_name         = "cog-${local.resource_prefix}-${format("%03d", 1)}"

  tags = local.common_tags
}

# Machine Learning Workspace
resource "azurerm_machine_learning_workspace" "main" {
  count                    = var.enable_machine_learning ? 1 : 0
  name                     = "mlw-${local.resource_prefix}-${format("%03d", 1)}"
  location                 = azurerm_resource_group.spokes[0].location
  resource_group_name      = azurerm_resource_group.spokes[0].name
  application_insights_id  = azurerm_application_insights.main[0].id
  key_vault_id            = azurerm_key_vault.main.id
  storage_account_id      = azurerm_storage_account.main.id

  # Security settings
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Application Insights for ML
resource "azurerm_application_insights" "main" {
  count               = var.enable_machine_learning ? 1 : 0
  name                = "appi-${local.resource_prefix}-ml-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  application_type    = "web"
  workspace_id        = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null

  tags = local.common_tags
}

# Container Registry for ML models
resource "azurerm_container_registry" "ml" {
  count               = var.enable_machine_learning ? 1 : 0
  name                = "acr${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}ml${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sku                 = "Premium"
  admin_enabled       = false

  # Security settings
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"

  tags = local.common_tags
}

# Private Endpoint for Cognitive Services
resource "azurerm_private_endpoint" "cognitive_services" {
  count               = var.enable_cognitive_services ? 1 : 0
  name                = "pep-${local.resource_prefix}-cog-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-cognitive-services"
    private_connection_resource_id = azurerm_cognitive_account.main[0].id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# Private Endpoint for Machine Learning Workspace
resource "azurerm_private_endpoint" "ml_workspace" {
  count               = var.enable_machine_learning ? 1 : 0
  name                = "pep-${local.resource_prefix}-mlw-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-ml-workspace"
    private_connection_resource_id = azurerm_machine_learning_workspace.main[0].id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# Private Endpoint for ML Container Registry
resource "azurerm_private_endpoint" "ml_acr" {
  count               = var.enable_machine_learning ? 1 : 0
  name                = "pep-${local.resource_prefix}-acr-ml-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-acr-ml"
    private_connection_resource_id = azurerm_container_registry.ml[0].id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}
