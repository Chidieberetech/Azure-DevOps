#================================================
# RESOURCE GROUPS AND CORE CONFIGURATION
#================================================

# Hub Resource Group - centralized hub infrastructure
resource "azurerm_resource_group" "hub" {
  name     = local.hub_resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Spoke Resource Groups with proper naming convention
resource "azurerm_resource_group" "spokes" {
  count    = var.spoke_count
  name     = "rg-trl-${local.environment_abbr}-${local.spoke_names[count.index]}-${format("%03d", count.index + 1)}"
  location = var.location
  tags     = local.common_tags
}

# Management Resource Group for operational tools
resource "azurerm_resource_group" "management" {
  name     = "rg-trl-${local.environment_abbr}-mgmt-${format("%03d", 1)}"
  location = var.location
  tags     = local.common_tags
}

#================================================
# CORE RESOURCES
#================================================

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "law-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days
  daily_quota_gb      = var.log_analytics_daily_quota_gb

  tags = local.common_tags
}

# Main Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "st${lower(local.environment_abbr)}${lower(local.location_abbr_value)}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.management.name
  location                 = azurerm_resource_group.management.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  # Security settings
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  min_tls_version                 = "TLS1_2"

  # Blob properties
  blob_properties {
    versioning_enabled       = true
    last_access_time_enabled = true
    change_feed_enabled      = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.common_tags

  # Ignore changes to network_rules since they're managed separately
  lifecycle {
    ignore_changes = [
      network_rules
    ]
  }
}

# Storage Account Network Rules - Applied separately to avoid service endpoint race condition
resource "azurerm_storage_account_network_rules" "main" {
  storage_account_id = azurerm_storage_account.main.id

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = var.spoke_count >= 1 ? [azurerm_subnet.spoke_alpha_workload[0].id] : []

  # Ensure service endpoints are fully configured before applying network rules
  depends_on = [
    azurerm_subnet.spoke_alpha_workload,
    azurerm_storage_account.main
  ]
}
