# Spoke Network Module - Main Configuration

# Spoke Virtual Network
resource "azurerm_virtual_network" "spoke" {
  name                = var.spoke_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.spoke_address_space
  tags                = var.tags
}

# Workload Subnet
resource "azurerm_subnet" "workload" {
  name                 = "trl-hubspoke-prod-snet-workload"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(var.spoke_address_space[0], 8, 1)]
}

# Database Subnet
resource "azurerm_subnet" "database" {
  name                 = "trl-hubspoke-prod-snet-db"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(var.spoke_address_space[0], 8, 2)]
}

# Private Endpoint Subnet
resource "azurerm_subnet" "private_endpoint" {
  name                 = "trl-hubspoke-prod-snet-pe"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(var.spoke_address_space[0], 8, 3)]
}

# Route Table for Spoke Subnets
resource "azurerm_route_table" "spoke" {
  name                = "trl-hubspoke-prod-rt-spoke"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  route {
    name                   = "DefaultRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }

  route {
    name           = "LocalVNet"
    address_prefix = var.spoke_address_space[0]
    next_hop_type  = "VnetLocal"
  }
}

# Associate Route Table with Workload Subnet
resource "azurerm_subnet_route_table_association" "workload" {
  subnet_id      = azurerm_subnet.workload.id
  route_table_id = azurerm_route_table.spoke.id
}

# Associate Route Table with Database Subnet
resource "azurerm_subnet_route_table_association" "database" {
  subnet_id      = azurerm_subnet.database.id
  route_table_id = azurerm_route_table.spoke.id
}

# VNet Peering to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "${var.spoke_vnet_name}-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = var.hub_vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

# VNet Peering from Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-${var.spoke_vnet_name}"
  resource_group_name       = var.hub_resource_group
  virtual_network_name      = "trl-hubspoke-prod-vnet-hub"
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
}
