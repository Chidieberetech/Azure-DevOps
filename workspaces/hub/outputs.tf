# Hub Workspace Outputs

#================================================
# RESOURCE GROUPS
#================================================

output "hub_resource_group_name" {
  description = "Name of the hub resource group (RG-TRL-Hub-weu)"
  value       = module.hub_infrastructure.hub_resource_group_name
}

output "spoke_resource_group_names" {
  description = "Names of the spoke resource groups"
  value       = module.hub_infrastructure.spoke_resource_group_names
}

#================================================
# NETWORK INFORMATION
#================================================

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = module.hub_infrastructure.hub_vnet_name
}

output "spoke_vnet_names" {
  description = "Names of the spoke virtual networks"
  value       = module.hub_infrastructure.spoke_vnet_names
}

#================================================
# SECURITY COMPONENTS
#================================================

output "firewall_public_ip" {
  description = "Public IP address of the Azure Firewall"
  value       = module.hub_infrastructure.firewall_public_ip
  sensitive   = false
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = module.hub_infrastructure.firewall_private_ip
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion"
  value       = module.hub_infrastructure.bastion_public_ip
  sensitive   = false
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.hub_infrastructure.key_vault_uri
}

#================================================
# VIRTUAL MACHINES
#================================================

output "spoke1_vm_private_ip" {
  description = "Private IP address of the Spoke 1 VM (10.1.4.10)"
  value       = module.hub_infrastructure.spoke1_vm_private_ip
}

output "spoke2_vm_private_ip" {
  description = "Private IP address of the Spoke 2 VM (10.2.4.10)"
  value       = module.hub_infrastructure.spoke2_vm_private_ip
}

output "vm_admin_username" {
  description = "Admin username for VMs"
  value       = module.hub_infrastructure.vm_admin_username
  sensitive   = false
}

#================================================
# CONNECTION INFORMATION
#================================================

output "rdp_connection_via_firewall" {
  description = "How to connect to VMs via Azure Firewall"
  value       = module.hub_infrastructure.rdp_connection_via_firewall
}

output "bastion_connection_info" {
  description = "How to connect to VMs via Azure Bastion"
  value       = module.hub_infrastructure.bastion_connection_url
}

#================================================
# STORAGE
#================================================

output "storage_account_name" {
  description = "Name of the main storage account"
  value       = module.hub_infrastructure.storage_account_name
}

output "diagnostics_storage_account_name" {
  description = "Name of the diagnostics storage account"
  value       = module.hub_infrastructure.diagnostics_storage_account_name
}
