# Outputs for TRL Hub and Spoke Infrastructure

#================================================
# RESOURCE GROUP OUTPUTS
#================================================

output "hub_resource_group_name" {
  description = "Name of the hub resource group"
  value       = azurerm_resource_group.hub.name
}

output "hub_resource_group_id" {
  description = "ID of the hub resource group"
  value       = azurerm_resource_group.hub.id
}

output "spoke_resource_group_names" {
  description = "Names of the spoke resource groups (Alpha, Beta)"
  value       = azurerm_resource_group.spokes[*].name
}

output "spoke_resource_group_ids" {
  description = "IDs of the spoke resource groups"
  value       = azurerm_resource_group.spokes[*].id
}

#================================================
# NETWORK OUTPUTS
#================================================

output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "spoke_vnet_ids" {
  description = "IDs of the spoke virtual networks"
  value       = azurerm_virtual_network.spokes[*].id
}

output "spoke_vnet_names" {
  description = "Names of the spoke virtual networks"
  value       = azurerm_virtual_network.spokes[*].name
}

#================================================
# SECURITY OUTPUTS
#================================================

output "firewall_public_ip" {
  description = "Public IP address of the Azure Firewall"
  value       = var.enable_firewall ? azurerm_public_ip.firewall[0].ip_address : null
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = var.enable_firewall ? azurerm_firewall.main[0].ip_configuration[0].private_ip_address : null
}

output "bastion_fqdn" {
  description = "FQDN of the Azure Bastion"
  value       = var.enable_bastion ? azurerm_bastion_host.main[0].dns_name : null
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion"
  value       = var.enable_bastion ? azurerm_public_ip.bastion[0].ip_address : null
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

#================================================
# COMPUTE OUTPUTS
#================================================

output "spoke_alpha_vm_private_ip" {
  description = "Private IP address of the Spoke Alpha VM"
  value       = var.spoke_count >= 1 ? azurerm_network_interface.spoke_alpha_vm[0].private_ip_address : null
}

output "spoke_beta_vm_private_ip" {
  description = "Private IP address of the Spoke Beta VM"
  value       = var.spoke_count >= 2 ? azurerm_network_interface.spoke_beta_vm[0].private_ip_address : null
}

output "vm_admin_username" {
  description = "Admin username for VMs"
  value       = var.admin_username
}

#================================================
# STORAGE OUTPUTS
#================================================

output "storage_account_name" {
  description = "Name of the main storage account"
  value       = azurerm_storage_account.main.name
}

output "diagnostics_storage_account_name" {
  description = "Name of the diagnostics storage account"
  value       = azurerm_storage_account.diagnostics.name
}

#================================================
# CONNECTION INFORMATION
#================================================

output "rdp_connection_via_firewall" {
  description = "RDP connection string via Azure Firewall"
  value       = var.enable_firewall && var.spoke_count >= 1 ? "Connect to ${azurerm_public_ip.firewall[0].ip_address}:3389 to reach Spoke Alpha VM" : "Firewall not enabled or no spokes deployed"
}

output "bastion_connection_url" {
  description = "Azure Bastion connection URL"
  value       = var.enable_bastion ? "Use Azure Portal to connect via Bastion to VMs" : "Bastion not enabled"
}

#================================================
# DATABASE OUTPUTS
#================================================

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = var.enable_sql_database ? azurerm_mssql_server.main[0].name : null
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = var.enable_sql_database ? azurerm_mssql_server.main[0].fully_qualified_domain_name : null
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = var.enable_sql_database ? azurerm_mssql_database.main[0].name : null
}

output "cosmos_db_account_name" {
  description = "Name of the Cosmos DB Account"
  value       = var.enable_cosmos_db ? azurerm_cosmosdb_account.main[0].name : null
}

output "cosmos_db_endpoint" {
  description = "Endpoint URL of the Cosmos DB Account"
  value       = var.enable_cosmos_db ? azurerm_cosmosdb_account.main[0].endpoint : null
  sensitive   = true
}

output "cosmos_db_primary_key" {
  description = "Primary access key for Cosmos DB"
  value       = var.enable_cosmos_db ? azurerm_cosmosdb_account.main[0].primary_key : null
  sensitive   = true
}
