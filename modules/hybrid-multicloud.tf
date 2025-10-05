#================================================
# HYBRID + MULTICLOUD SERVICES
#================================================

# Azure Arc for Kubernetes
resource "azurerm_arc_kubernetes_cluster" "main" {
  count               = var.enable_arc_kubernetes ? 1 : 0
  name                = "arck8s-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location
  agent_public_key_certificate = var.arc_kubernetes_public_key

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Site Recovery Services Vault for Hybrid DR
resource "azurerm_recovery_services_vault" "hybrid" {
  count                        = var.enable_site_recovery ? 1 : 0
  name                         = "rsv-${local.resource_prefix}-hybrid-${format("%03d", 1)}"
  location                     = azurerm_resource_group.management.location
  resource_group_name          = azurerm_resource_group.management.name
  sku                         = "Standard"
  storage_mode_type           = "GeoRedundant"
  cross_region_restore_enabled = true
  soft_delete_enabled         = true

  tags = local.common_tags
}

# Azure Stack HCI (Simulated with resource placeholders)
# Note: Actual Azure Stack HCI requires physical hardware
resource "azurerm_resource_group" "stack_hci" {
  count    = var.enable_stack_hci ? 1 : 0
  name     = "rg-${local.resource_prefix}-stackhci-${format("%03d", 1)}"
  location = var.location
  tags     = local.common_tags
}

# Azure Database Migration Service
resource "azurerm_database_migration_service" "main" {
  count               = var.enable_database_migration ? 1 : 0
  name                = "dms-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  subnet_id           = azurerm_subnet.shared_services.id
  sku_name            = "Standard_1vCores"

  tags = local.common_tags
}

# Storage Sync for hybrid storage
resource "azurerm_storage_sync" "hybrid" {
  count               = var.enable_storage_sync ? 1 : 0
  name                = "ss-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  tags = local.common_tags
}

# Storage Sync Group
resource "azurerm_storage_sync_group" "main" {
  count            = var.enable_storage_sync ? 1 : 0
  name             = "ssg-main"
  storage_sync_id  = azurerm_storage_sync.hybrid[0].id
}

# ExpressRoute Gateway for hybrid connectivity
resource "azurerm_virtual_network_gateway" "expressroute" {
  count               = var.enable_expressroute_gateway ? 1 : 0
  name                = "ergw-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  type     = "ExpressRoute"
  vpn_type = "RouteBased"

  sku           = var.expressroute_gateway_sku
  generation    = "Generation1"
  active_active = false
  enable_bgp    = false

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.expressroute_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  tags = local.common_tags
}

# Public IP for ExpressRoute Gateway (required)
resource "azurerm_public_ip" "expressroute_gateway" {
  count               = var.enable_expressroute_gateway ? 1 : 0
  name                = "pip-${local.resource_prefix}-ergw-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# VPN Gateway for site-to-site connectivity
resource "azurerm_virtual_network_gateway" "vpn" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "vgw-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  sku           = var.vpn_gateway_sku
  generation    = "Generation1"
  active_active = false
  enable_bgp    = false

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  tags = local.common_tags
}

# Public IP for VPN Gateway (required)
resource "azurerm_public_ip" "vpn_gateway" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "pip-${local.resource_prefix}-vgw-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}
