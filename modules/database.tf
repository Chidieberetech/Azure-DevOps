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
  name                         = "${local.resource_prefix}-sql-${random_string.suffix.result}"
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
  name      = "${local.resource_prefix}-sqldb-main"
  server_id = azurerm_mssql_server.main[0].id
  sku_name  = var.sql_database_sku

  # Free tier configuration
  max_size_gb = 2

  tags = local.common_tags
}

# Private Endpoint for SQL Database
resource "azurerm_private_endpoint" "sql_database" {
  count               = var.enable_sql_database ? 1 : 0
  name                = "${local.resource_prefix}-pep-sql"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke1_private_endpoint[0].id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-sql"
    private_connection_resource_id = azurerm_mssql_server.main[0].id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.enable_private_dns && var.enable_sql_database ? [1] : []
    content {
      name                 = "sql-dns-zone-group"
      private_dns_zone_ids = [azurerm_private_dns_zone.sql_database[0].id]
    }
  }
}

#================================================
# COSMOS DB (Optional)
#================================================

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  count               = var.enable_cosmos_db ? 1 : 0
  name                = "${local.resource_prefix}-cosmos-${random_string.suffix.result}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  # Free tier configuration
  enable_free_tier = true

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
  public_network_access_enabled = false

  tags = local.common_tags
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "main" {
  count               = var.enable_cosmos_db ? 1 : 0
  name                = "main-database"
  resource_group_name = azurerm_resource_group.spokes[0].name
  account_name        = azurerm_cosmosdb_account.main[0].name

  # Free tier: 1000 RU/s
  throughput = 400
}

# Cosmos DB SQL Container
resource "azurerm_cosmosdb_sql_container" "main" {
  count               = var.enable_cosmos_db ? 1 : 0
  name                = "main-container"
  resource_group_name = azurerm_resource_group.spokes[0].name
  account_name        = azurerm_cosmosdb_account.main[0].name
  database_name       = azurerm_cosmosdb_sql_database.main[0].name
  partition_key_path  = "/definition/id"

  # Free tier configuration
  throughput = 400
}
