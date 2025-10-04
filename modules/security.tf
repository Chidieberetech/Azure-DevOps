#================================================
# AZURE FIREWALL
#================================================

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  count               = var.enable_firewall ? 1 : 0
  name                = "${local.resource_prefix}-pip-afw"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Azure Firewall Policy
resource "azurerm_firewall_policy" "main" {
  count               = var.enable_firewall ? 1 : 0
  name                = "${local.resource_prefix}-afwp"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  tags                = local.common_tags

  dns {
    proxy_enabled = true
  }

  threat_intelligence_mode = "Alert"
}

# Firewall Policy Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "main" {
  count              = var.enable_firewall ? 1 : 0
  name               = "DefaultRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.main[0].id
  priority           = 500

  application_rule_collection {
    name     = "AllowWebTraffic"
    priority = 500
    action   = "Allow"

    rule {
      name = "AllowHTTPSOutbound"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_fqdns = ["*"]
    }
  }

  network_rule_collection {
    name     = "AllowNetworkTraffic"
    priority = 400
    action   = "Allow"

    rule {
      name                  = "AllowDNS"
      protocols             = ["UDP"]
      source_addresses      = ["10.1.0.0/16", "10.2.0.0/16"]
      destination_addresses = ["168.63.129.16", "8.8.8.8"]
      destination_ports     = ["53"]
    }
  }
}

# Azure Firewall
resource "azurerm_firewall" "main" {
  count               = var.enable_firewall ? 1 : 0
  name                = "${local.resource_prefix}-afw"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.main[0].id
  tags                = local.common_tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

#================================================
# AZURE BASTION
#================================================

# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "${local.resource_prefix}-pip-bas"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  count               = var.enable_bastion ? 1 : 0
  name                = "${local.resource_prefix}-bas"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  copy_paste_enabled  = true
  file_copy_enabled   = true
  tunneling_enabled   = true
  tags                = local.common_tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

#================================================
# AZURE KEY VAULT
#================================================

# Azure Key Vault
resource "azurerm_key_vault" "main" {
  name                        = "${local.resource_prefix}-kv-${random_string.suffix.result}"
  location                    = azurerm_resource_group.hub.location
  resource_group_name         = azurerm_resource_group.hub.name
  enabled_for_disk_encryption = true
  enabled_for_deployment      = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = var.key_vault_soft_delete_retention_days
  purge_protection_enabled    = false
  sku_name                    = "standard"

  public_network_access_enabled = false

  tags = local.common_tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
    ]
  }
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault" {
  name                = "${local.resource_prefix}-pep-kv"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  subnet_id           = azurerm_subnet.hub_private_endpoint.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.enable_private_dns ? [1] : []
    content {
      name                 = "keyvault-dns-zone-group"
      private_dns_zone_ids = [azurerm_private_dns_zone.key_vault[0].id]
    }
  }
}

# Generate VM admin password
resource "random_password" "vm_admin_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Store VM admin password in Key Vault
resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "vm-admin-password"
  value        = random_password.vm_admin_password.result
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.common_tags

  depends_on = [azurerm_key_vault.main]
}

# Generate SQL admin password
resource "random_password" "sql_admin_password" {
  count   = var.enable_sql_database ? 1 : 0
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Store SQL admin password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  count        = var.enable_sql_database ? 1 : 0
  name         = "sql-admin-password"
  value        = random_password.sql_admin_password[0].result
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.common_tags

  depends_on = [azurerm_key_vault.main]
}
