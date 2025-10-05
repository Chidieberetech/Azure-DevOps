#================================================
# IDENTITY SERVICES
#================================================

# Azure Active Directory Domain Services
resource "azurerm_active_directory_domain_service" "main" {
  count               = var.enable_aad_ds ? 1 : 0
  name                = "aadds-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  domain_name           = var.aad_ds_domain_name
  sku                   = "Standard"
  filtered_sync_enabled = false

  initial_replica_set {
    subnet_id = azurerm_subnet.shared_services.id
  }

  tags = local.common_tags
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "main" {
  count               = var.enable_managed_identity ? 1 : 0
  location            = azurerm_resource_group.hub.location
  name                = "id-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.hub.name

  tags = local.common_tags
}

# Azure AD B2C Tenant (requires manual setup)
# Note: B2C tenant creation via Terraform is limited
resource "azurerm_aadb2c_directory" "main" {
  count                   = var.enable_aad_b2c ? 1 : 0
  resource_group_name     = azurerm_resource_group.hub.name
  resource_name           = "b2c-${local.resource_prefix}-${format("%03d", 1)}"
  domain_name             = "${local.resource_prefix}b2c.onmicrosoft.com"
  country_code            = var.aad_b2c_country_code
  data_residency_location = var.location
  sku_name                = "PremiumP1"

  tags = local.common_tags
}

# Key Vault for Identity secrets
resource "azurerm_key_vault" "identity" {
  count                      = var.enable_identity_keyvault ? 1 : 0
  name                       = "kv-${local.resource_prefix}-id-${format("%03d", 1)}"
  location                   = azurerm_resource_group.hub.location
  resource_group_name        = azurerm_resource_group.hub.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  # Security settings
  public_network_access_enabled = false
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.common_tags
}

# Access Policy for User Assigned Identity
resource "azurerm_key_vault_access_policy" "managed_identity" {
  count        = var.enable_managed_identity && var.enable_identity_keyvault ? 1 : 0
  key_vault_id = azurerm_key_vault.identity[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.main[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  certificate_permissions = [
    "Get",
    "List"
  ]

  key_permissions = [
    "Get",
    "List",
    "Decrypt",
    "Encrypt"
  ]
}

# Private Endpoint for Identity Key Vault
resource "azurerm_private_endpoint" "identity_keyvault" {
  count               = var.enable_identity_keyvault ? 1 : 0
  name                = "pep-${local.resource_prefix}-id-kv-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  subnet_id           = azurerm_subnet.hub_private_endpoint.id

  private_service_connection {
    name                           = "psc-identity-keyvault"
    private_connection_resource_id = azurerm_key_vault.identity[0].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# Role assignments for common scenarios
resource "azurerm_role_assignment" "managed_identity_contributor" {
  count                = var.enable_managed_identity ? 1 : 0
  scope                = azurerm_resource_group.spokes[0].id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.main[0].principal_id
}

# Custom role definition for application access
resource "azurerm_role_definition" "app_access" {
  count       = var.enable_custom_roles ? 1 : 0
  role_definition_id = uuidv5("dns", "app-access-${local.resource_prefix}")
  name        = "App Access - ${local.resource_prefix}"
  scope       = azurerm_resource_group.spokes[0].id
  description = "Custom role for application access in spoke environments"

  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      "Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action",
      "Microsoft.KeyVault/vaults/secrets/getSecret/action"
    ]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_resource_group.spokes[0].id
  ]
}
