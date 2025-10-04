# Outputs for TRL Hub and Spoke Infrastructure

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
  description = "ID of the Azure Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

#================================================
# COMPUTE OUTPUTS
#================================================

output "spoke1_vm_id" {
  description = "ID of the VM in spoke 1"
  value       = var.spoke_count >= 1 ? azurerm_windows_virtual_machine.spoke1_vm[0].id : null
}

output "spoke1_vm_private_ip" {
  description = "Private IP address of the VM in spoke 1"
  value       = var.spoke_count >= 1 ? azurerm_network_interface.spoke1_vm[0].private_ip_address : null
}

output "spoke2_vm_id" {
  description = "ID of the VM in spoke 2"
  value       = var.spoke_count >= 2 ? azurerm_windows_virtual_machine.spoke2_vm[0].id : null
}

output "spoke2_vm_private_ip" {
  description = "Private IP address of the VM in spoke 2"
  value       = var.spoke_count >= 2 ? azurerm_network_interface.spoke2_vm[0].private_ip_address : null
}

#================================================
# STORAGE OUTPUTS
#================================================

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

#================================================
# DATABASE OUTPUTS
#================================================

output "sql_server_id" {
  description = "ID of the SQL Server"
  value       = var.enable_sql_database ? azurerm_mssql_server.main[0].id : null
}

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = var.enable_sql_database ? azurerm_mssql_server.main[0].name : null
}

output "sql_server_fqdn" {
  description = "FQDN of the SQL Server"
  value       = var.enable_sql_database ? azurerm_mssql_server.main[0].fully_qualified_domain_name : null
}

output "sql_database_id" {
  description = "ID of the SQL Database"
  value       = var.enable_sql_database ? azurerm_mssql_database.main[0].id : null
}

output "cosmos_db_id" {
  description = "ID of the Cosmos DB account"
  value       = var.enable_cosmos_db ? azurerm_cosmosdb_account.main[0].id : null
}

output "cosmos_db_endpoint" {
  description = "Endpoint of the Cosmos DB account"
  value       = var.enable_cosmos_db ? azurerm_cosmosdb_account.main[0].endpoint : null
}

#================================================
# RESOURCE GROUP OUTPUTS
#================================================

output "hub_resource_group_id" {
  description = "ID of the hub resource group"
  value       = azurerm_resource_group.hub.id
}

output "spoke_resource_group_ids" {
  description = "IDs of the spoke resource groups"
  value       = azurerm_resource_group.spokes[*].id
}

output "management_resource_group_id" {
  description = "ID of the management resource group"
  value       = azurerm_resource_group.management.id
}

#================================================
# DNS OUTPUTS
#================================================

output "private_dns_zone_ids" {
  description = "IDs of the private DNS zones"
  value = var.enable_private_dns ? {
    key_vault     = azurerm_private_dns_zone.key_vault[0].id
    storage_blob  = azurerm_private_dns_zone.storage_blob[0].id
    storage_file  = azurerm_private_dns_zone.storage_file[0].id
    sql_database  = var.enable_sql_database ? azurerm_private_dns_zone.sql_database[0].id : null
  } : null
}
