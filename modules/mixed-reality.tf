#================================================
# MIXED REALITY SERVICES
#================================================

# Spatial Anchors Account
resource "azurerm_spatial_anchors_account" "main" {
  count               = var.enable_spatial_anchors ? 1 : 0
  name                = "spa-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name

  tags = local.common_tags
}

# Storage Account for Mixed Reality content
resource "azurerm_storage_account" "mixed_reality" {
  count                    = var.enable_mixed_reality_storage ? 1 : 0
  name                     = "st${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}mr${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.spokes[0].name
  location                 = azurerm_resource_group.spokes[0].location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security settings
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  # Enable large file shares for 3D content
  large_file_share_enabled = true

  tags = local.common_tags
}

# CDN Profile for Mixed Reality content delivery
resource "azurerm_cdn_profile" "mixed_reality" {
  count               = var.enable_mixed_reality_cdn ? 1 : 0
  name                = "cdn-${local.resource_prefix}-mr-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  sku                 = "Standard_Microsoft"

  tags = local.common_tags
}

# CDN Endpoint for Mixed Reality content
resource "azurerm_cdn_endpoint" "mixed_reality" {
  count                         = var.enable_mixed_reality_cdn ? 1 : 0
  name                          = "cdn-${local.resource_prefix}-mr-${format("%03d", 1)}"
  profile_name                  = azurerm_cdn_profile.mixed_reality[0].name
  location                      = azurerm_resource_group.spokes[0].location
  resource_group_name           = azurerm_resource_group.spokes[0].name
  is_http_allowed               = false
  is_https_allowed              = true
  querystring_caching_behaviour = "IgnoreQueryString"

  origin {
    name      = "mr-storage"
    host_name = azurerm_storage_account.mixed_reality[0].primary_blob_host
  }

  tags = local.common_tags
}

# Container Registry for Mixed Reality applications
resource "azurerm_container_registry" "mixed_reality" {
  count               = var.enable_mixed_reality_acr ? 1 : 0
  name                = "acr${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}mr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  sku                 = "Premium"
  admin_enabled       = false

  # Security settings
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"

  tags = local.common_tags
}

# Private Endpoints for Mixed Reality Services
resource "azurerm_private_endpoint" "mixed_reality_storage" {
  count               = var.enable_mixed_reality_storage ? 1 : 0
  name                = "pep-${local.resource_prefix}-mr-st-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-mixed-reality-storage"
    private_connection_resource_id = azurerm_storage_account.mixed_reality[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "mixed_reality_acr" {
  count               = var.enable_mixed_reality_acr ? 1 : 0
  name                = "pep-${local.resource_prefix}-mr-acr-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-mixed-reality-acr"
    private_connection_resource_id = azurerm_container_registry.mixed_reality[0].id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}
