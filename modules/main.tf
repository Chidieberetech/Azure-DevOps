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
  name     = "rg-trl-${local.env_abbr[var.environment]}-${local.spoke_names[count.index]}-${format("%03d", count.index + 1)}"
  location = var.location
  tags     = local.common_tags
}

# Management Resource Group for operational tools
resource "azurerm_resource_group" "management" {
  name     = "rg-trl-${local.env_abbr[var.environment]}-mgmt-${format("%03d", 1)}"
  location = var.location
  tags     = local.common_tags
}
