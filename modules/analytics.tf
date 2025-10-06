#================================================
# ANALYTICS RESOURCES
#================================================

# Log Analytics Workspace for Analytics (renamed to avoid conflict with main.tf)
resource "azurerm_log_analytics_workspace" "analytics" {
  count               = var.enable_analytics ? 1 : 0
  name                = "law-analytics-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days

  tags = local.common_tags
}

# Application Insights for analytics (renamed to avoid conflict)
resource "azurerm_application_insights" "analytics" {
  count               = var.enable_analytics && var.enable_application_insights ? 1 : 0
  name                = "ai-analytics-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  workspace_id        = azurerm_log_analytics_workspace.analytics[0].id
  application_type    = var.application_insights_type

  tags = local.common_tags
}

# Data Factory for data integration and orchestration
resource "azurerm_data_factory" "main" {
  count               = var.enable_analytics && var.enable_data_factory ? 1 : 0
  name                = "adf-trl-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Storage Account for Data Lake
resource "azurerm_storage_account" "data_lake" {
  count                    = var.enable_analytics && var.enable_data_lake ? 1 : 0
  name                     = "stdl${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.management.name
  location                 = azurerm_resource_group.management.location
  account_tier             = "Standard"
  account_replication_type = var.data_lake_replication_type
  account_kind            = "StorageV2"
  is_hns_enabled          = true  # Enable hierarchical namespace for Data Lake

  # Security settings
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  min_tls_version                 = "TLS1_2"

  # Network rules
  network_rules {
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    bypass         = ["AzureServices"]
  }

  tags = local.common_tags
}

# Data Lake containers
resource "azurerm_storage_data_lake_gen2_filesystem" "bronze" {
  count              = var.enable_analytics && var.enable_data_lake ? 1 : 0
  name               = "bronze"
  storage_account_id = azurerm_storage_account.data_lake[0].id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "silver" {
  count              = var.enable_analytics && var.enable_data_lake ? 1 : 0
  name               = "silver"
  storage_account_id = azurerm_storage_account.data_lake[0].id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "gold" {
  count              = var.enable_analytics && var.enable_data_lake ? 1 : 0
  name               = "gold"
  storage_account_id = azurerm_storage_account.data_lake[0].id
}

# Synapse Analytics Workspace
resource "azurerm_synapse_workspace" "main" {
  count                                = var.enable_analytics && var.enable_synapse ? 1 : 0
  name                                 = "syn-trl-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  location                             = azurerm_resource_group.management.location
  resource_group_name                  = azurerm_resource_group.management.name
  storage_data_lake_gen2_filesystem_id = var.enable_data_lake ? azurerm_storage_data_lake_gen2_filesystem.bronze[0].id : null
  sql_administrator_login              = var.synapse_sql_admin_login
  sql_administrator_login_password     = var.synapse_sql_admin_password

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Synapse SQL Pool (Data Warehouse)
resource "azurerm_synapse_sql_pool" "main" {
  count                = var.enable_analytics && var.enable_synapse && var.enable_synapse_sql_pool ? 1 : 0
  name                 = "sqlpool${lower(local.env_abbr[var.environment])}"
  synapse_workspace_id = azurerm_synapse_workspace.main[0].id
  sku_name             = var.synapse_sql_pool_sku
  create_mode          = "Default"
  storage_account_type = "GRS"

  tags = local.common_tags
}

# Synapse Spark Pool
resource "azurerm_synapse_spark_pool" "main" {
  count                = var.enable_analytics && var.enable_synapse && var.enable_synapse_spark_pool ? 1 : 0
  name                 = "sparkpool${lower(local.env_abbr[var.environment])}"
  synapse_workspace_id = azurerm_synapse_workspace.main[0].id
  node_size_family     = "MemoryOptimized"
  node_size            = var.synapse_spark_node_size
  node_count           = var.synapse_spark_node_count
  spark_version        = "3.3"

  auto_scale {
    max_node_count = var.synapse_spark_max_nodes
    min_node_count = var.synapse_spark_min_nodes
  }

  auto_pause {
    delay_in_minutes = var.synapse_spark_auto_pause_delay
  }

  tags = local.common_tags
}

# Private Endpoints for Analytics Services
resource "azurerm_private_endpoint" "data_factory" {
  count               = var.enable_analytics && var.enable_data_factory && var.enable_private_endpoints ? 1 : 0
  name                = "pe-adf-trl-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-adf-trl-${local.env_abbr[var.environment]}"
    private_connection_resource_id = azurerm_data_factory.main[0].id
    subresource_names              = ["dataFactory"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "data_lake" {
  count               = var.enable_analytics && var.enable_data_lake && var.enable_private_endpoints ? 1 : 0
  name                = "pe-stdl-trl-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-stdl-trl-${local.env_abbr[var.environment]}"
    private_connection_resource_id = azurerm_storage_account.data_lake[0].id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "synapse" {
  count               = var.enable_analytics && var.enable_synapse && var.enable_private_endpoints ? 1 : 0
  name                = "pe-syn-trl-${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-syn-trl-${local.env_abbr[var.environment]}"
    private_connection_resource_id = azurerm_synapse_workspace.main[0].id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}
