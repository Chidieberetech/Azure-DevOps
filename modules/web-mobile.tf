#================================================
# WEB AND MOBILE SERVICES
#================================================

# App Service Plan
resource "azurerm_service_plan" "main" {
  count               = var.enable_app_service ? 1 : 0
  name                = "asp-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku

  tags = local.common_tags
}

# Web App
resource "azurerm_linux_web_app" "main" {
  count               = var.enable_app_service ? 1 : 0
  name                = "app-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  service_plan_id     = azurerm_service_plan.main[0].id

  site_config {
    always_on = var.app_service_plan_sku != "F1" && var.app_service_plan_sku != "D1"

    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "ENVIRONMENT" = var.environment
  }

  tags = local.common_tags
}

# Function App
resource "azurerm_linux_function_app" "main" {
  count               = var.enable_function_app ? 1 : 0
  name                = "func-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  service_plan_id     = azurerm_service_plan.main[0].id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  site_config {
    application_stack {
      node_version = "18"
    }
  }

  app_settings = {
    "ENVIRONMENT" = var.environment
  }

  tags = local.common_tags
}

# Static Web App
resource "azurerm_static_site" "main" {
  count               = var.enable_static_web_app ? 1 : 0
  name                = "stapp-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = "East US2"  # Static Web Apps have limited region availability
  sku_tier            = "Free"
  sku_size            = "Free"

  tags = local.common_tags
}

# Remove duplicate container app environment and container app - using ones from containers.tf
# Remove duplicate API management - using one from general.tf
# Remove duplicate notification hub resources - using ones from general.tf
# Remove duplicate search service - using one from general.tf

# CDN Profile
resource "azurerm_cdn_profile" "main" {
  count               = var.enable_cdn ? 1 : 0
  name                = "cdn-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  sku                 = "Standard_Microsoft"

  tags = local.common_tags
}

# CDN Endpoint
resource "azurerm_cdn_endpoint" "main" {
  count               = var.enable_cdn ? 1 : 0
  name                = "cdn-endpoint-${local.resource_prefix}-${format("%03d", 1)}"
  profile_name        = azurerm_cdn_profile.main[0].name
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name

  origin {
    name      = "origin1"
    host_name = var.enable_app_service ? azurerm_linux_web_app.main[0].default_hostname : "example.com"
  }

  tags = local.common_tags
}
