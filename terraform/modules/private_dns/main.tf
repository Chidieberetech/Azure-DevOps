# Private DNS Module - Main Configuration

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone for Storage Account Blob
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone for Storage Account File
resource "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone for SQL Database
resource "azurerm_private_dns_zone" "sql_database" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone for Cosmos DB
resource "azurerm_private_dns_zone" "cosmos_db" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone for Container Registry
resource "azurerm_private_dns_zone" "container_registry" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link Private DNS Zones to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_hub" {
  name                  = "trl-hubspoke-prod-pdns-link-kv-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_hub" {
  name                  = "trl-hubspoke-prod-pdns-link-blob-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_hub" {
  name                  = "trl-hubspoke-prod-pdns-link-file-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_database_hub" {
  name                  = "trl-hubspoke-prod-pdns-link-sql-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql_database.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_db_hub" {
  name                  = "trl-hubspoke-prod-pdns-link-cosmos-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_db.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "container_registry_hub" {
  name                  = "trl-hubspoke-prod-pdns-link-acr-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.container_registry.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# Link Private DNS Zones to Spoke VNets
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_spoke" {
  count                 = length(var.spoke_vnet_ids)
  name                  = "trl-hubspoke-prod-pdns-link-kv-spoke${count.index + 1}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.spoke_vnet_ids[count.index]
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_spoke" {
  count                 = length(var.spoke_vnet_ids)
  name                  = "trl-hubspoke-prod-pdns-link-blob-spoke${count.index + 1}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = var.spoke_vnet_ids[count.index]
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_spoke" {
  count                 = length(var.spoke_vnet_ids)
  name                  = "trl-hubspoke-prod-pdns-link-file-spoke${count.index + 1}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = var.spoke_vnet_ids[count.index]
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_database_spoke" {
  count                 = length(var.spoke_vnet_ids)
  name                  = "trl-hubspoke-prod-pdns-link-sql-spoke${count.index + 1}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql_database.name
  virtual_network_id    = var.spoke_vnet_ids[count.index]
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_db_spoke" {
  count                 = length(var.spoke_vnet_ids)
  name                  = "trl-hubspoke-prod-pdns-link-cosmos-spoke${count.index + 1}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_db.name
  virtual_network_id    = var.spoke_vnet_ids[count.index]
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "container_registry_spoke" {
  count                 = length(var.spoke_vnet_ids)
  name                  = "trl-hubspoke-prod-pdns-link-acr-spoke${count.index + 1}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.container_registry.name
  virtual_network_id    = var.spoke_vnet_ids[count.index]
  registration_enabled  = false
  tags                  = var.tags
}
