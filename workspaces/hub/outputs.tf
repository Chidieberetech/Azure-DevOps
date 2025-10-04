# Hub Workspace Outputs

output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = module.hub_infrastructure.hub_vnet_id
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = module.hub_infrastructure.firewall_private_ip
}

output "key_vault_id" {
  description = "ID of the Azure Key Vault"
  value       = module.hub_infrastructure.key_vault_id
}

output "bastion_fqdn" {
  description = "FQDN of the Azure Bastion"
  value       = module.hub_infrastructure.bastion_fqdn
}
