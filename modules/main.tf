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

#================================================
# LOG ANALYTICS WORKSPACE
#================================================

# Log Analytics Workspace for monitoring and logging
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "law-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

#================================================
# RECOVERY SERVICES VAULT
#================================================

# Recovery Services Vault for VM backups
resource "azurerm_recovery_services_vault" "main" {
  count                        = var.enable_backup ? 1 : 0
  name                         = "rsv-${local.resource_prefix}-${format("%03d", 1)}"
  location                     = azurerm_resource_group.management.location
  resource_group_name          = azurerm_resource_group.management.name
  sku                          = "Standard"
  cross_region_restore_enabled = false
  soft_delete_enabled          = true
  tags                         = local.common_tags
}

# Backup Policy for VMs
resource "azurerm_backup_policy_vm" "main" {
  count               = var.enable_backup ? 1 : 0
  name                = "backup-policy-vm"
  resource_group_name = azurerm_resource_group.management.name
  recovery_vault_name = azurerm_recovery_services_vault.main[0].name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = var.backup_retention_days
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

#================================================
# NETWORK WATCHER
#================================================

# Network Watcher for network monitoring and diagnostics
resource "azurerm_network_watcher" "main" {
  name                = "nw-${local.resource_prefix}-${format("%03d", 1)}"
  location            = var.location
  resource_group_name = azurerm_resource_group.management.name
  tags                = local.common_tags
}
