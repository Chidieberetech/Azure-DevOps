#================================================
# SQL DATABASE
#================================================

# Data source to get Key Vault secret for SQL password
data "azurerm_key_vault_secret" "sql_password" {
  count        = var.enable_sql_database ? 1 : 0
  name         = "sql-admin-password"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_secret.sql_admin_password]
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  count                        = var.enable_sql_database ? 1 : 0
  name                         = "sql-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name          = azurerm_resource_group.spokes[0].name
  location                     = azurerm_resource_group.spokes[0].location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = data.azurerm_key_vault_secret.sql_password[0].value

  public_network_access_enabled = false

  tags = local.common_tags

  identity {
    type = "SystemAssigned"
  }
}

# SQL Database (Free tier: S0)
resource "azurerm_mssql_database" "main" {
  count     = var.enable_sql_database ? 1 : 0
  name      = "sqldb-${local.resource_prefix}-main-${format("%03d", 1)}"
  server_id = azurerm_mssql_server.main[0].id
  sku_name  = var.sql_database_sku

  # Free tier configuration
  max_size_gb = 2

  tags = local.common_tags
}

# Private Endpoint for SQL Database
resource "azurerm_private_endpoint" "sql_database" {
  count               = var.enable_sql_database ? 1 : 0
  name                = "pep-${local.resource_prefix}-sql-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-${local.resource_prefix}-sql-${format("%03d", 1)}"
    private_connection_resource_id = azurerm_mssql_server.main[0].id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-${local.resource_prefix}-sql"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_database[0].id]
  }

  tags = local.common_tags
}

# Private DNS Zone for SQL Database
resource "azurerm_private_dns_zone" "sql_database" {
  count               = var.enable_sql_database ? 1 : 0
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# Link Private DNS Zone to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql_database_hub" {
  count                 = var.enable_sql_database ? 1 : 0
  name                  = "pdzvnl-${local.resource_prefix}-sql-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_database[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Link Private DNS Zone to Spoke VNets
resource "azurerm_private_dns_zone_virtual_network_link" "sql_database_spokes" {
  count                 = var.enable_sql_database ? var.spoke_count : 0
  name                  = "pdzvnl-${local.resource_prefix}-sql-${local.spoke_names[count.index]}"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_database[0].name
  virtual_network_id    = azurerm_virtual_network.spokes[count.index].id
  registration_enabled  = false
  tags                  = local.common_tags
}

#================================================
# COSMOS DB
#================================================

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  count               = var.enable_cosmos_db ? 1 : 0
  name                = "cosmos-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = azurerm_resource_group.spokes[0].location
    failover_priority = 0
  }

  # Security settings
  public_network_access_enabled     = false
  network_acl_bypass_for_azure_services = false

  tags = local.common_tags
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "main" {
  count               = var.enable_cosmos_db ? 1 : 0
  name                = "cosmosdb-${local.resource_prefix}-main"
  resource_group_name = azurerm_resource_group.spokes[0].name
  account_name        = azurerm_cosmosdb_account.main[0].name
}

# Cosmos DB SQL Container
resource "azurerm_cosmosdb_sql_container" "main" {
  count               = var.enable_cosmos_db ? 1 : 0
  name                = "container-main"
  resource_group_name = azurerm_resource_group.spokes[0].name
  account_name        = azurerm_cosmosdb_account.main[0].name
  database_name       = azurerm_cosmosdb_sql_database.main[0].name
  partition_key_paths = ["/partitionKey"]
}

# Private DNS Zone for Cosmos DB
resource "azurerm_private_dns_zone" "cosmos_db" {
  count               = var.enable_cosmos_db ? 1 : 0
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# Link Private DNS Zone to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_db_hub" {
  count                 = var.enable_cosmos_db ? 1 : 0
  name                  = "pdzvnl-${local.resource_prefix}-cosmos-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_db[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Link Private DNS Zone to Spoke VNets
resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_db_spokes" {
  count                 = var.enable_cosmos_db ? var.spoke_count : 0
  name                  = "pdzvnl-${local.resource_prefix}-cosmos-${local.spoke_names[count.index]}"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_db[0].name
  virtual_network_id    = azurerm_virtual_network.spokes[count.index].id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Private Endpoint for Cosmos DB
resource "azurerm_private_endpoint" "cosmos_db" {
  count               = var.enable_cosmos_db ? 1 : 0
  name                = "pep-${local.resource_prefix}-cosmos-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  tags = local.common_tags

  private_service_connection {
    name                           = "psc-cosmos-db"
    private_connection_resource_id = azurerm_cosmosdb_account.main[0].id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cosmos-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos_db[0].id]
  }
}
