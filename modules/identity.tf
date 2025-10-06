#================================================
# IDENTITY AND ACCESS MANAGEMENT
#================================================

# Azure Active Directory Domain Services
resource "azurerm_active_directory_domain_service" "main" {
  count               = var.enable_aad_ds ? 1 : 0
  name                = "aadds-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name

  domain_name           = var.aad_ds_domain_name
  sku                   = "Standard"

  initial_replica_set {
    subnet_id = azurerm_subnet.spoke_alpha_workload[0].id
  }

  tags = local.common_tags
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "main" {
  count               = var.enable_managed_identity ? 1 : 0
  name                = "id-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  tags = local.common_tags
}

# Azure Active Directory B2C Tenant (Note: B2C tenant creation via Terraform has limitations)
# This creates a placeholder resource group for B2C configuration
resource "azurerm_resource_group" "aad_b2c" {
  count    = var.enable_aad_b2c ? 1 : 0
  name     = "rg-trl-${local.env_abbr[var.environment]}-b2c-${format("%03d", 1)}"
  location = var.location
  # Note: country_code is applied during tenant creation, not resource group

  tags = merge(local.common_tags, {
    Purpose = "Azure AD B2C Configuration"
    CountryCode = var.aad_b2c_country_code
  })
}

# Dedicated Key Vault for Identity Services
resource "azurerm_key_vault" "identity" {
  count                       = var.enable_identity_keyvault ? 1 : 0
  name                        = "kv-${local.resource_prefix}-id-${format("%03d", 1)}"
  location                    = azurerm_resource_group.management.location
  resource_group_name         = azurerm_resource_group.management.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = var.environment == "prod" ? true : false
  sku_name                    = var.key_vault_sku

  # Network ACLs for identity services
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

# Key Vault access policy for Managed Identity
resource "azurerm_key_vault_access_policy" "managed_identity" {
  count        = var.enable_managed_identity && var.enable_identity_keyvault ? 1 : 0
  key_vault_id = azurerm_key_vault.identity[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.main[0].principal_id

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Recover", "Backup", "Restore"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
  ]

  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Import", "Recover", "Backup", "Restore"
  ]
}

# Private Endpoint for Identity Key Vault
resource "azurerm_private_endpoint" "identity_keyvault" {
  count               = var.enable_identity_keyvault ? 1 : 0
  name                = "pe-kv-id-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-identity-keyvault"
    private_connection_resource_id = azurerm_key_vault.identity[0].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# Role Assignment for Managed Identity
resource "azurerm_role_assignment" "managed_identity_contributor" {
  count                = var.enable_managed_identity ? 1 : 0
  scope                = azurerm_resource_group.management.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.main[0].principal_id
}

# Custom RBAC Role Definition
resource "azurerm_role_definition" "custom_identity_operator" {
  count              = var.enable_custom_roles ? 1 : 0
  role_definition_id = "00000000-0000-0000-0000-000000000001"
  name               = "TRL Identity Operator"
  scope              = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  description        = "Custom role for TRL identity operations"

  permissions {
    actions = [
      "Microsoft.ManagedIdentity/userAssignedIdentities/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.KeyVault/vaults/read",
      "Microsoft.KeyVault/vaults/secrets/read",
      "Microsoft.Authorization/roleAssignments/read"
    ]

    not_actions = []

    data_actions = [
      "Microsoft.KeyVault/vaults/secrets/getSecret/action"
    ]

    not_data_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  ]
}
