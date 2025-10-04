#================================================
# HUB NETWORK INFRASTRUCTURE
#================================================

# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = "${local.resource_prefix}-vnet-hub"
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

# Shared Services Subnet
resource "azurerm_subnet" "shared_services" {
  name                 = "${local.resource_prefix}-snet-shared"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_subnets.shared_services]
}

# Private Endpoint Subnet in Hub
resource "azurerm_subnet" "hub_private_endpoint" {
  name                 = "${local.resource_prefix}-snet-pe-hub"
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
  name                = "${local.resource_prefix}-vnet-spoke${count.index + 1}"
  location            = azurerm_resource_group.spokes[count.index].location
  resource_group_name = azurerm_resource_group.spokes[count.index].name
  address_space       = count.index == 0 ? local.spoke1_address_space : local.spoke2_address_space
  tags                = local.common_tags
}

# Spoke 1 Subnets
resource "azurerm_subnet" "spoke1_workload" {
  count                = var.spoke_count >= 1 ? 1 : 0
  name                 = "${local.resource_prefix}-snet-workload-spoke1"
  resource_group_name  = azurerm_resource_group.spokes[0].name
  virtual_network_name = azurerm_virtual_network.spokes[0].name
  address_prefixes     = [local.spoke1_subnets.workload_subnet]
}

resource "azurerm_subnet" "spoke1_database" {
  count                = var.spoke_count >= 1 ? 1 : 0
  name                 = "${local.resource_prefix}-snet-db-spoke1"
  resource_group_name  = azurerm_resource_group.spokes[0].name
  virtual_network_name = azurerm_virtual_network.spokes[0].name
  address_prefixes     = [local.spoke1_subnets.database_subnet]
}

resource "azurerm_subnet" "spoke1_private_endpoint" {
  count                = var.spoke_count >= 1 ? 1 : 0
  name                 = "${local.resource_prefix}-snet-pe-spoke1"
  resource_group_name  = azurerm_resource_group.spokes[0].name
  virtual_network_name = azurerm_virtual_network.spokes[0].name
  address_prefixes     = [local.spoke1_subnets.private_endpoint]
}

# Spoke 2 Subnets
resource "azurerm_subnet" "spoke2_workload" {
  count                = var.spoke_count >= 2 ? 1 : 0
  name                 = "${local.resource_prefix}-snet-workload-spoke2"
  resource_group_name  = azurerm_resource_group.spokes[1].name
  virtual_network_name = azurerm_virtual_network.spokes[1].name
  address_prefixes     = [local.spoke2_subnets.workload_subnet]
}

resource "azurerm_subnet" "spoke2_app_service" {
  count                = var.spoke_count >= 2 ? 1 : 0
  name                 = "${local.resource_prefix}-snet-app-spoke2"
  resource_group_name  = azurerm_resource_group.spokes[1].name
  virtual_network_name = azurerm_virtual_network.spokes[1].name
  address_prefixes     = [local.spoke2_subnets.app_service_subnet]
}

resource "azurerm_subnet" "spoke2_private_endpoint" {
  count                = var.spoke_count >= 2 ? 1 : 0
  name                 = "${local.resource_prefix}-snet-pe-spoke2"
  resource_group_name  = azurerm_resource_group.spokes[1].name
  virtual_network_name = azurerm_virtual_network.spokes[1].name
  address_prefixes     = [local.spoke2_subnets.private_endpoint]
}

#================================================
# ROUTE TABLES AND ROUTING
#================================================

# Route Table for Spoke Networks
resource "azurerm_route_table" "spokes" {
  count               = var.spoke_count
  name                = "${local.resource_prefix}-rt-spoke${count.index + 1}"
  location            = azurerm_resource_group.spokes[count.index].location
  resource_group_name = azurerm_resource_group.spokes[count.index].name
  tags                = local.common_tags

  route {
    name                   = "DefaultRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.enable_firewall ? azurerm_firewall.main[0].ip_configuration[0].private_ip_address : null
  }

  depends_on = [azurerm_firewall.main]
}

# Associate Route Tables with Spoke Subnets
resource "azurerm_subnet_route_table_association" "spoke1_workload" {
  count          = var.spoke_count >= 1 && var.enable_firewall ? 1 : 0
  subnet_id      = azurerm_subnet.spoke1_workload[0].id
  route_table_id = azurerm_route_table.spokes[0].id
}

resource "azurerm_subnet_route_table_association" "spoke1_database" {
  count          = var.spoke_count >= 1 && var.enable_firewall ? 1 : 0
  subnet_id      = azurerm_subnet.spoke1_database[0].id
  route_table_id = azurerm_route_table.spokes[0].id
}

resource "azurerm_subnet_route_table_association" "spoke2_workload" {
  count          = var.spoke_count >= 2 && var.enable_firewall ? 1 : 0
  subnet_id      = azurerm_subnet.spoke2_workload[0].id
  route_table_id = azurerm_route_table.spokes[1].id
}

resource "azurerm_subnet_route_table_association" "spoke2_app_service" {
  count          = var.spoke_count >= 2 && var.enable_firewall ? 1 : 0
  subnet_id      = azurerm_subnet.spoke2_app_service[0].id
  route_table_id = azurerm_route_table.spokes[1].id
}

#================================================
# VNET PEERING
#================================================

# Hub to Spoke Peering
resource "azurerm_virtual_network_peering" "hub_to_spokes" {
  count                        = var.spoke_count
  name                         = "hub-to-spoke${count.index + 1}"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spokes[count.index].id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

# Spoke to Hub Peering
resource "azurerm_virtual_network_peering" "spokes_to_hub" {
  count                        = var.spoke_count
  name                         = "spoke${count.index + 1}-to-hub"
  resource_group_name          = azurerm_resource_group.spokes[count.index].name
  virtual_network_name         = azurerm_virtual_network.spokes[count.index].name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

#================================================
# PRIVATE DNS ZONES
#================================================

# Private DNS Zones for Azure Services
resource "azurerm_private_dns_zone" "key_vault" {
  count               = var.enable_private_dns ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "storage_blob" {
  count               = var.enable_private_dns ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "storage_file" {
  count               = var.enable_private_dns ? 1 : 0
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "sql_database" {
  count               = var.enable_private_dns && var.enable_sql_database ? 1 : 0
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# Link Private DNS Zones to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "hub_key_vault" {
  count                 = var.enable_private_dns ? 1 : 0
  name                  = "${local.resource_prefix}-pdns-link-kv-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_storage_blob" {
  count                 = var.enable_private_dns ? 1 : 0
  name                  = "${local.resource_prefix}-pdns-link-blob-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob[0].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Link Private DNS Zones to Spoke VNets
resource "azurerm_private_dns_zone_virtual_network_link" "spokes_key_vault" {
  count                 = var.enable_private_dns ? var.spoke_count : 0
  name                  = "${local.resource_prefix}-pdns-link-kv-spoke${count.index + 1}"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = azurerm_virtual_network.spokes[count.index].id
  registration_enabled  = false
  tags                  = local.common_tags
}
