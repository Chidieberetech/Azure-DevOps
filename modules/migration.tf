#================================================
# MIGRATION SERVICES
#================================================

# Azure Migrate Project
resource "azurerm_migrate_project" "main" {
  count               = var.enable_migrate_project ? 1 : 0
  name                = "migr-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

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

# Data Box for offline data transfer
# Note: Data Box orders are typically created through Azure portal or APIs
resource "azurerm_resource_group_template_deployment" "databox_order" {
  count               = var.enable_databox ? 1 : 0
  name                = "databox-${local.resource_prefix}"
  resource_group_name = azurerm_resource_group.management.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    "contentVersion" = "1.0.0.0"
    "resources" = [
      {
        "type"       = "Microsoft.DataBox/jobs"
        "apiVersion" = "2022-12-01"
        "name"       = "databox-${local.resource_prefix}"
        "location"   = var.location
        "sku" = {
          "name" = "DataBox"
        }
        "properties" = {
          "transferType" = "ImportToAzure"
          "details" = {
            "jobDetailsType" = "DataBox"
            "contactDetails" = {
              "contactName" = var.migration_contact_name
              "phone"       = var.migration_contact_phone
              "emailList"   = [var.migration_contact_email]
            }
            "shippingAddress" = {
              "streetAddress1" = var.migration_shipping_address
              "city"          = var.migration_shipping_city
              "stateOrProvince" = var.migration_shipping_state
              "country"       = var.migration_shipping_country
              "postalCode"    = var.migration_shipping_postal_code
            }
            "destinationAccountDetails" = [
              {
                "accountId" = azurerm_storage_account.migration[0].id
                "dataDestinationType" = "StorageAccount"
              }
            ]
          }
        }
        "tags" = local.common_tags
      }
    ]
  })
}

# Site Recovery Vault for VM migration
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

# App Service Migration Assistant (placeholder)
resource "azurerm_app_service_plan" "migration_staging" {
  count               = var.enable_app_migration ? 1 : 0
  name                = "asp-${local.resource_prefix}-migr-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }

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

# Azure Import/Export Service (managed through portal/CLI typically)
# Storage containers for import/export jobs
resource "azurerm_storage_container" "import_export" {
  count                 = var.enable_import_export ? 1 : 0
  name                  = "import-export"
  storage_account_id    = azurerm_storage_account.migration[0].id
  container_access_type = "private"
}
