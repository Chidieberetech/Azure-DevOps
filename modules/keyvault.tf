#================================================
# KEY VAULT CONFIGURATION
#================================================

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "kv-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_sku

  # Security settings
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false
  soft_delete_retention_days      = var.enable_key_vault_soft_delete ? 7 : null

  # Network access rules
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = local.common_tags
}

# Key Vault Access Policy for current user/service principal
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
  ]

  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"
  ]
}

# Generate a random password for VM admin
resource "random_password" "vm_admin_password" {
  length  = 16
  special = true
}

# Store VM admin password in Key Vault
resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "vm-admin-password"
  value        = random_password.vm_admin_password.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.current_user]

  tags = local.common_tags
}

# Generate a random password for SQL admin
resource "random_password" "sql_admin_password" {
  count   = var.enable_sql_database ? 1 : 0
  length  = 16
  special = true
}

# Store SQL admin password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  count        = var.enable_sql_database ? 1 : 0
  name         = "sql-admin-password"
  value        = random_password.sql_admin_password[0].result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.current_user]

  tags = local.common_tags
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault" {
  count               = var.enable_private_dns ? 1 : 0
  name                = "pep-${local.resource_prefix}-kv-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  subnet_id           = azurerm_subnet.hub_private_endpoint.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-key-vault"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.enable_private_dns ? [1] : []
    content {
      name                 = "key-vault-dns-zone-group"
      private_dns_zone_ids = [azurerm_private_dns_zone.key_vault[0].id]
    }
  }
}

#================================================
# PRIVATE DNS ZONES
#================================================

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "key_vault" {
  count               = var.enable_private_dns ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# Private DNS Zone for Storage Blob
resource "azurerm_private_dns_zone" "storage_blob" {
  count               = var.enable_private_dns ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# Private DNS Zone for Storage File
resource "azurerm_private_dns_zone" "storage_file" {
  count               = var.enable_private_dns ? 1 : 0
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# Private DNS Zone for SQL Database
resource "azurerm_private_dns_zone" "sql_database" {
  count               = var.enable_private_dns && var.enable_sql_database ? 1 : 0
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# Private DNS Zone for Cosmos DB
resource "azurerm_private_dns_zone" "cosmos_db" {
  count               = var.enable_private_dns && var.enable_cosmos_db ? 1 : 0
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# Link Private DNS Zones to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "key_vault_hub" {
  count                 = var.enable_private_dns ? 1 : 0
  name                  = "kv-dns-link-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_hub" {
  count                 = var.enable_private_dns ? 1 : 0
  name                  = "storage-blob-dns-link-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_hub" {
  count                 = var.enable_private_dns ? 1 : 0
  name                  = "storage-file-dns-link-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Link SQL Database DNS Zone to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql_database_hub" {
  count                 = var.enable_private_dns && var.enable_sql_database ? 1 : 0
  name                  = "sql-dns-link-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_database[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Link Cosmos DB DNS Zone to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_db_hub" {
  count                 = var.enable_private_dns && var.enable_cosmos_db ? 1 : 0
  name                  = "cosmos-dns-link-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_db[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Link Private DNS Zones to Spoke VNets
resource "azurerm_private_dns_zone_virtual_network_link" "key_vault_spokes" {
  count                 = var.enable_private_dns ? var.spoke_count : 0
  name                  = "kv-dns-link-spoke${count.index + 1}"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = azurerm_virtual_network.spokes[count.index].id
  registration_enabled  = false
  tags                  = local.common_tags
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

# Link SQL Database DNS Zone to Spoke VNets
resource "azurerm_private_dns_zone_virtual_network_link" "sql_database_spokes" {
  count                 = var.enable_private_dns && var.enable_sql_database ? var.spoke_count : 0
  name                  = "sql-dns-link-spoke-${local.spoke_names[count.index]}"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_database[0].name
  virtual_network_id    = azurerm_virtual_network.spokes[count.index].id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Link Cosmos DB DNS Zone to Spoke VNets
resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_db_spokes" {
  count                 = var.enable_private_dns && var.enable_cosmos_db ? var.spoke_count : 0
  name                  = "cosmos-dns-link-spoke-${local.spoke_names[count.index]}"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_db[0].name
  virtual_network_id    = azurerm_virtual_network.spokes[count.index].id
  registration_enabled  = false
  tags                  = local.common_tags
}
