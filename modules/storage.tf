#================================================
# STORAGE SERVICES
#================================================

# Premium Storage Account for high-performance workloads
resource "azurerm_storage_account" "premium" {
  count                    = var.enable_premium_storage ? 1 : 0
  name                     = "stprem${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.management.name
  location                 = azurerm_resource_group.management.location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "BlockBlobStorage"

  # Security settings
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  min_tls_version                 = "TLS1_2"

  tags = local.common_tags
}

# Data Lake Storage Gen2 Account
resource "azurerm_storage_account" "datalake" {
  count                    = var.enable_data_lake_storage ? 1 : 0
  name                     = "stdl${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.management.name
  location                 = azurerm_resource_group.management.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  is_hns_enabled          = true  # Hierarchical namespace for Data Lake

  # Security settings
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  min_tls_version                 = "TLS1_2"

  tags = local.common_tags
}

# Diagnostics Storage Account for VM Boot Diagnostics
resource "azurerm_storage_account" "diagnostics" {
  name                     = "stdiag${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.hub.name
  location                 = azurerm_resource_group.hub.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  # Allow public access for diagnostics
  public_network_access_enabled   = false
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

# Storage Containers - Fixed argument names
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

# File Share for shared data - Fixed argument names
resource "azurerm_storage_share" "shared" {
  name                 = "shared-data"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 50
}

# Private DNS Zones for Storage Services
resource "azurerm_private_dns_zone" "storage_blob" {
  count               = var.enable_private_dns ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.hub.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone" "storage_file" {
  count               = var.enable_private_dns ? 1 : 0
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.hub.name

  tags = local.common_tags
}

# Virtual Network Links for Storage Private DNS Zones
resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_hub" {
  count                 = var.enable_private_dns ? 1 : 0
  name                  = "pdns-link-storage-blob-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_hub" {
  count                 = var.enable_private_dns ? 1 : 0
  name                  = "pdns-link-storage-file-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_spokes" {
  count                 = var.enable_private_dns ? var.spoke_count : 0
  name                  = "storage-blob-dns-link-spoke${count.index + 1}"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob[0].name
  virtual_network_id    = azurerm_virtual_network.spokes[count.index].id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_spokes" {
  count                 = var.enable_private_dns ? var.spoke_count : 0
  name                  = "storage-file-dns-link-spoke${count.index + 1}"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file[0].name
  virtual_network_id    = azurerm_virtual_network.spokes[count.index].id
  registration_enabled  = false
  tags                  = local.common_tags
}
