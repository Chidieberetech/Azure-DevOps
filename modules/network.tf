#================================================
# HUB NETWORK INFRASTRUCTURE
#================================================

# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${local.resource_prefix}-hub-${format("%03d", 1)}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = local.hub_address_space
  tags                = local.common_tags
}

# Azure Firewall Subnet (required name)
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_subnets.firewall_subnet]
}

# Azure Bastion Subnet (required name)
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_subnets.bastion_subnet]
}

# Gateway Subnet for VPN Gateway (if needed)
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_subnets.gateway_subnet]
}

# Shared Services Subnet
resource "azurerm_subnet" "shared_services" {
  name                 = "snet-${local.resource_prefix}-shared-${format("%03d", 1)}"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_subnets.shared_services]
}

# Private Endpoint Subnet in Hub
resource "azurerm_subnet" "hub_private_endpoint" {
  name                 = "snet-${local.resource_prefix}-pe-hub-${format("%03d", 1)}"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_subnets.private_endpoint]
}

#================================================
# SPOKE NETWORK INFRASTRUCTURE
#================================================

# Spoke Virtual Networks
resource "azurerm_virtual_network" "spokes" {
  count               = var.spoke_count
  name                = "vnet-${local.resource_prefix}-${local.spoke_names[count.index]}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[count.index].location
  resource_group_name = azurerm_resource_group.spokes[count.index].name
  address_space       = count.index == 0 ? local.spoke_alpha_address_space :
                       count.index == 1 ? local.spoke_beta_address_space :
                       local.spoke_gamma_address_space
  tags                = local.common_tags
}

# Spoke Alpha Subnets
resource "azurerm_subnet" "spoke_alpha_workload" {
  count                = var.spoke_count >= 1 ? 1 : 0
  name                 = "snet-${local.resource_prefix}-alpha-workload-${format("%03d", 1)}"
  resource_group_name  = azurerm_resource_group.spokes[0].name
  virtual_network_name = azurerm_virtual_network.spokes[0].name
  address_prefixes     = [local.spoke_alpha_subnets.workload_subnet]
}

resource "azurerm_subnet" "spoke_alpha_vm" {
  count                = var.spoke_count >= 1 ? 1 : 0
  name                 = "snet-${local.resource_prefix}-alpha-vm-${format("%03d", 1)}"
  resource_group_name  = azurerm_resource_group.spokes[0].name
  virtual_network_name = azurerm_virtual_network.spokes[0].name
  address_prefixes     = [local.spoke_alpha_subnets.vm_subnet]
}

resource "azurerm_subnet" "spoke_alpha_database" {
  count                = var.spoke_count >= 1 ? 1 : 0
  name                 = "snet-${local.resource_prefix}-alpha-db-${format("%03d", 1)}"
  resource_group_name  = azurerm_resource_group.spokes[0].name
  virtual_network_name = azurerm_virtual_network.spokes[0].name
  address_prefixes     = [local.spoke_alpha_subnets.database_subnet]
}

resource "azurerm_subnet" "spoke_alpha_private_endpoint" {
  count                = var.spoke_count >= 1 ? 1 : 0
  name                 = "snet-${local.resource_prefix}-alpha-pe-${format("%03d", 1)}"
  resource_group_name  = azurerm_resource_group.spokes[0].name
  virtual_network_name = azurerm_virtual_network.spokes[0].name
  address_prefixes     = [local.spoke_alpha_subnets.private_endpoint]
}

# Spoke Beta Subnets
resource "azurerm_subnet" "spoke_beta_workload" {
  count                = var.spoke_count >= 2 ? 1 : 0
  name                 = "snet-${local.resource_prefix}-beta-workload-${format("%03d", 1)}"
  resource_group_name  = azurerm_resource_group.spokes[1].name
  virtual_network_name = azurerm_virtual_network.spokes[1].name
  address_prefixes     = [local.spoke_beta_subnets.workload_subnet]
}

resource "azurerm_subnet" "spoke_beta_vm" {
  count                = var.spoke_count >= 2 ? 1 : 0
  name                 = "snet-${local.resource_prefix}-beta-vm-${format("%03d", 1)}"
  resource_group_name  = azurerm_resource_group.spokes[1].name
  virtual_network_name = azurerm_virtual_network.spokes[1].name
  address_prefixes     = [local.spoke_beta_subnets.vm_subnet]
}

#================================================
# VNET PEERING CONFIGURATION
#================================================

# Hub to Spoke Peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count                     = var.spoke_count
  name                      = "peer-hub-to-${local.spoke_names[count.index]}"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spokes[count.index].id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
}

# Spoke to Hub Peering
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count                     = var.spoke_count
  name                      = "peer-${local.spoke_names[count.index]}-to-hub"
  resource_group_name       = azurerm_resource_group.spokes[count.index].name
  virtual_network_name      = azurerm_virtual_network.spokes[count.index].name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = var.enable_firewall ? true : false
}
