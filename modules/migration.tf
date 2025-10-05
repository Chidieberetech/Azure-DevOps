#================================================
# MIGRATION SERVICES
#================================================

# Storage Account for migration data
resource "azurerm_storage_account" "migration" {
  count                    = var.enable_migration_storage ? 1 : 0
  name                     = "st${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}migr${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.management.name
  location                 = azurerm_resource_group.management.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security settings
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.common_tags
}

# Database Migration Service
resource "azurerm_database_migration_service" "main" {
  count               = var.enable_database_migration_service ? 1 : 0
  name                = "dms-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  subnet_id           = azurerm_subnet.shared_services.id
  sku_name            = "Standard_1vCores"

  tags = local.common_tags
}

# Site Recovery Vault for migration
resource "azurerm_recovery_services_vault" "migration" {
  count                        = var.enable_site_recovery_migration ? 1 : 0
  name                         = "rsv-${local.resource_prefix}-migr-${format("%03d", 1)}"
  location                     = azurerm_resource_group.management.location
  resource_group_name          = azurerm_resource_group.management.name
  sku                         = "Standard"
  storage_mode_type           = "GeoRedundant"
  cross_region_restore_enabled = true
  soft_delete_enabled         = true

  tags = local.common_tags
}

# Backup Policy for migrated VMs
resource "azurerm_backup_policy_vm" "migration" {
  count               = var.enable_migration_backup ? 1 : 0
  name                = "bkp-policy-migration"
  recovery_vault_name = azurerm_recovery_services_vault.migration[0].name
  resource_group_name = azurerm_resource_group.management.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 30
  }

  retention_weekly {
    count    = 12
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count    = 5
    weekdays = ["Sunday"]
    weeks    = ["First"]
    months   = ["January"]
  }
}

# App Service Migration staging environment
resource "azurerm_service_plan" "migration_staging" {
  count               = var.enable_app_migration ? 1 : 0
  name                = "asp-${local.resource_prefix}-migr-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  os_type             = "Linux"
  sku_name            = "S1"

  tags = local.common_tags
}

# Private Endpoints for Migration Services
resource "azurerm_private_endpoint" "migration_storage" {
  count               = var.enable_migration_storage ? 1 : 0
  name                = "pep-${local.resource_prefix}-migr-st-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  subnet_id           = azurerm_subnet.hub_private_endpoint.id

  private_service_connection {
    name                           = "psc-migration-storage"
    private_connection_resource_id = azurerm_storage_account.migration[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# Storage containers for import/export jobs
resource "azurerm_storage_container" "import_export" {
  count                 = var.enable_import_export ? 1 : 0
  name                  = "import-export"
  storage_account_id    = azurerm_storage_account.migration[0].id
  container_access_type = "private"
}
