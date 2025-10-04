#================================================
# RESOURCE GROUPS AND CORE CONFIGURATION
#================================================

# Hub Resource Group
resource "azurerm_resource_group" "hub" {
  name     = "${local.resource_prefix}-rg-hub"
  location = var.location
  tags     = local.common_tags
}

# Spoke Resource Groups
resource "azurerm_resource_group" "spokes" {
  count    = var.spoke_count
  name     = "${local.resource_prefix}-rg-spoke${count.index + 1}"
  location = var.location
  tags     = local.common_tags
}

# Management Resource Group
resource "azurerm_resource_group" "management" {
  name     = "${local.resource_prefix}-rg-mgmt"
  location = var.location
  tags     = local.common_tags
}
