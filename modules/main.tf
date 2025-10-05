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
# SHARED STORAGE ACCOUNT
#================================================

# Primary storage account for general use
resource "azurerm_storage_account" "main" {
  name                     = "st${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.management.name
  location                 = azurerm_resource_group.management.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  # Security settings
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  min_tls_version                 = "TLS1_2"

  # Blob properties
  blob_properties {
    versioning_enabled       = true
    last_access_time_enabled = true
    change_feed_enabled      = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  # Network access
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = var.spoke_count >= 1 ? [azurerm_subnet.spoke_alpha_workload[0].id] : []
  }

  tags = local.common_tags

  depends_on = [azurerm_subnet.spoke_alpha_workload]
}

#================================================
# LOG ANALYTICS WORKSPACE (MOVED FROM MONITOR.TF)
#================================================

# Central Log Analytics Workspace for the entire infrastructure
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "law-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days
  daily_quota_gb      = var.log_analytics_daily_quota_gb

  tags = local.common_tags
}

#================================================
# KEY VAULT
#================================================

# Central Key Vault for secrets management
resource "azurerm_key_vault" "main" {
  count                       = var.enable_key_vault ? 1 : 0
  name                        = "kv-${local.resource_prefix}-${format("%03d", 1)}"
  location                    = azurerm_resource_group.management.location
  resource_group_name         = azurerm_resource_group.management.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = var.environment == "prod" ? true : false
  sku_name                    = var.key_vault_sku

  # Network ACLs
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    virtual_network_subnet_ids = var.spoke_count >= 1 ? [
      azurerm_subnet.spoke_alpha_workload[0].id,
      azurerm_subnet.spoke_alpha_private_endpoint[0].id
    ] : []
  }

  tags = local.common_tags

  depends_on = [azurerm_subnet.spoke_alpha_workload, azurerm_subnet.spoke_alpha_private_endpoint]
}

# Key Vault access policy for the current service principal
resource "azurerm_key_vault_access_policy" "current" {
  count        = var.enable_key_vault ? 1 : 0
  key_vault_id = azurerm_key_vault.main[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import",
    "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update",
    "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"
  ]

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]

  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers",
    "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers",
    "Purge", "Recover", "Restore", "SetIssuers", "Update"
  ]
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
  cross_region_restore_enabled = var.environment == "prod" ? true : false
  soft_delete_enabled          = true

  # Enhanced security features for production
  immutability = var.environment == "prod" ? "Locked" : "Unlocked"

  encryption {
    key_id                            = var.enable_key_vault ? azurerm_key_vault_key.backup[0].id : null
    infrastructure_encryption_enabled = var.environment == "prod" ? true : false
  }

  tags = local.common_tags

  depends_on = [azurerm_key_vault_key.backup]
}

# Key for backup vault encryption
resource "azurerm_key_vault_key" "backup" {
  count        = var.enable_backup && var.enable_key_vault ? 1 : 0
  name         = "backup-encryption-key"
  key_vault_id = azurerm_key_vault.main[0].id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"
  ]

  depends_on = [azurerm_key_vault_access_policy.current]
}

# Enhanced Backup Policy for VMs with multiple retention options
resource "azurerm_backup_policy_vm" "main" {
  count               = var.enable_backup ? 1 : 0
  name                = "backup-policy-vm-${var.environment}"
  resource_group_name = azurerm_resource_group.management.name
  recovery_vault_name = azurerm_recovery_services_vault.main[0].name
  timezone            = "UTC"

  backup {
    frequency = "Daily"
    time      = "02:00"
  }

  retention_daily {
    count = var.backup_retention_days
  }

  retention_weekly {
    count    = var.environment == "prod" ? 52 : 12
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = var.environment == "prod" ? 60 : 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count    = var.environment == "prod" ? 10 : 0
    weekdays = ["Sunday"]
    weeks    = ["First"]
    months   = ["January"]
  }

  instant_restore_retention_days = var.environment == "prod" ? 5 : 2
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

# Flow logs for network monitoring (without NSG dependency)
resource "azurerm_network_watcher_flow_log" "main" {
  count                = var.enable_monitoring ? 1 : 0
  network_watcher_name = azurerm_network_watcher.main.name
  resource_group_name  = azurerm_resource_group.management.name
  name                 = "flowlog-${local.resource_prefix}"
  # Removed NSG dependency - all traffic flows via Azure Firewall
  storage_account_id   = azurerm_storage_account.main.id
  enabled              = true
  version              = 2

  retention_policy {
    enabled = true
    days    = var.log_retention_days
  }

  traffic_analytics {
    enabled               = var.enable_monitoring
    workspace_id          = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].workspace_id : null
    workspace_region      = var.location
    workspace_resource_id = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null
    interval_in_minutes   = 10
  }

  tags = local.common_tags

  depends_on = [azurerm_log_analytics_workspace.main]
}

# Network flow logs for Azure Firewall monitoring (Hub and Spoke topology)
resource "azurerm_network_watcher_flow_log" "firewall" {
  count                = var.enable_monitoring && var.enable_firewall ? 1 : 0
  network_watcher_name = azurerm_network_watcher.main.name
  resource_group_name  = azurerm_resource_group.management.name
  name                 = "flowlog-firewall-${local.resource_prefix}"
  # Monitor Azure Firewall subnet for traffic analysis
  target_resource_id   = azurerm_subnet.firewall.id
  storage_account_id        = azurerm_storage_account.main.id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.log_retention_days
  }

  traffic_analytics {
    enabled               = var.enable_monitoring
    workspace_id          = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].workspace_id : null
    workspace_region      = var.location
    workspace_resource_id = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null
    interval_in_minutes   = 10
  }

  tags = local.common_tags

  depends_on = [azurerm_log_analytics_workspace.main, azurerm_subnet.firewall]
}

#================================================
# AZURE DEFENDER FOR CLOUD (FORMERLY SECURITY CENTER)
#================================================

# Azure Defender for Cloud Contact
resource "azurerm_security_center_contact" "main" {
  count               = var.enable_security_center && var.security_contact_email != "" ? 1 : 0
  name                 = "default1"
  email                = var.security_contact_email
  phone                = "+1-555-555-5555"
  alert_notifications = true
  alerts_to_admins    = true
}

# Azure Defender pricing tiers - Updated for current service names
resource "azurerm_security_center_subscription_pricing" "vm" {
  count         = var.enable_security_center ? 1 : 0
  tier          = var.environment == "prod" ? "Standard" : "Free"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "storage" {
  count         = var.enable_security_center ? 1 : 0
  tier          = var.environment == "prod" ? "Standard" : "Free"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "keyvault" {
  count         = var.enable_security_center ? 1 : 0
  tier          = var.environment == "prod" ? "Standard" : "Free"
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_subscription_pricing" "sql" {
  count         = var.enable_security_center && var.enable_sql_database ? 1 : 0
  tier          = var.environment == "prod" ? "Standard" : "Free"
  resource_type = "SqlServers"
}

resource "azurerm_security_center_subscription_pricing" "app_service" {
  count         = var.enable_security_center && var.enable_app_service ? 1 : 0
  tier          = var.environment == "prod" ? "Standard" : "Free"
  resource_type = "AppServices"
}

resource "azurerm_security_center_subscription_pricing" "containers" {
  count         = var.enable_security_center && var.enable_container_registry ? 1 : 0
  tier          = var.environment == "prod" ? "Standard" : "Free"
  resource_type = "ContainerRegistry"
}

resource "azurerm_security_center_subscription_pricing" "kubernetes" {
  count         = var.enable_security_center && var.enable_aks ? 1 : 0
  tier          = var.environment == "prod" ? "Standard" : "Free"
  resource_type = "KubernetesService"
}

#================================================
# AZURE POLICY ASSIGNMENTS
#================================================

# Policy assignment for enhanced security
resource "azurerm_subscription_policy_assignment" "security_baseline" {
  count                = var.enable_security_center ? 1 : 0
  name                 = "security-baseline-${var.environment}"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f"
  subscription_id      = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  display_name         = "Azure Security Benchmark for ${var.environment}"
  description          = "Apply Azure Security Benchmark policies for enhanced security posture"

  parameters = jsonencode({
    effect = {
      value = var.environment == "prod" ? "Audit" : "AuditIfNotExists"
    }
  })

  identity {
    type = "SystemAssigned"
  }

  location = var.location
}

# NOTE: NSG resources removed - all traffic flows via Azure Firewall in Hub and Spoke topology

#================================================
# DIAGNOSTICS AND MONITORING CONFIGURATION
#================================================

# Activity log diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "subscription" {
  count                      = var.enable_monitoring ? 1 : 0
  name                       = "diag-${local.resource_prefix}-subscription"
  target_resource_id         = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Recommendation"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Autoscale"
  }

  enabled_log {
    category = "ResourceHealth"
  }
}
