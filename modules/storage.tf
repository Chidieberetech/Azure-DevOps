#================================================
# STORAGE ACCOUNTS
#================================================

# Main Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "st${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.spokes[0].name
  location                 = azurerm_resource_group.spokes[0].location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  # Security settings
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  # Enable blob encryption
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = local.common_tags
}

# Diagnostics Storage Account for VM Boot Diagnostics
resource "azurerm_storage_account" "diagnostics" {
  name                     = "stdiag${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.hub.name
  location                 = azurerm_resource_group.hub.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Allow public access for diagnostics
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  tags = local.common_tags
}

# Private Endpoint for Blob Storage
resource "azurerm_private_endpoint" "storage_blob" {
  count               = var.spoke_count >= 1 ? 1 : 0
  name                = "pep-${local.resource_prefix}-st-blob-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-storage-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-storage-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob[0].id]
  }

  tags = local.common_tags
}

# Private Endpoint for File Storage
resource "azurerm_private_endpoint" "storage_file" {
  count               = var.spoke_count >= 1 ? 1 : 0
  name                = "pep-${local.resource_prefix}-st-file-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-storage-file"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-storage-file"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_file[0].id]
  }

  tags = local.common_tags
}

# Storage Containers
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# File Share for shared data
resource "azurerm_storage_share" "shared" {
  name                 = "shared-data"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 50
}
