# Outputs for Azure Hub and Spoke Infrastructure

output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = module.hub_network.vnet_id
}

output "spoke1_vnet_id" {
  description = "ID of the spoke 1 virtual network"
  value       = module.spoke1_network.vnet_id
}

output "spoke2_vnet_id" {
  description = "ID of the spoke 2 virtual network"
  value       = module.spoke2_network.vnet_id
}

output "firewall_public_ip" {
  description = "Public IP address of the Azure Firewall"
  value       = module.firewall.public_ip_address
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = module.firewall.private_ip_address
}

output "bastion_fqdn" {
  description = "FQDN of the Azure Bastion"
  value       = module.bastion.fqdn
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.vault_uri
}

output "spoke1_vm_private_ip" {
  description = "Private IP of the VM in spoke 1"
  value       = module.spoke1_vm.private_ip_address
}

output "spoke2_vm_private_ip" {
  description = "Private IP of the VM in spoke 2"
  value       = module.spoke2_vm.private_ip_address
}

output "storage_account_primary_endpoint" {
  description = "Primary endpoint of the storage account"
  value       = module.storage.primary_blob_endpoint
}

output "sql_server_fqdn" {
  description = "FQDN of the SQL Server"
  value       = module.sql_database.server_fqdn
}
