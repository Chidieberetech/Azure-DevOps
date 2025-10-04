# Private DNS Module - Outputs

output "keyvault_dns_zone_id" {
  description = "ID of the Key Vault private DNS zone"
  value       = azurerm_private_dns_zone.keyvault.id
}

output "storage_blob_dns_zone_id" {
  description = "ID of the Storage Blob private DNS zone"
  value       = azurerm_private_dns_zone.storage_blob.id
}

output "storage_file_dns_zone_id" {
  description = "ID of the Storage File private DNS zone"
  value       = azurerm_private_dns_zone.storage_file.id
}

output "sql_database_dns_zone_id" {
  description = "ID of the SQL Database private DNS zone"
  value       = azurerm_private_dns_zone.sql_database.id
}

output "cosmos_db_dns_zone_id" {
  description = "ID of the Cosmos DB private DNS zone"
  value       = azurerm_private_dns_zone.cosmos_db.id
}

output "container_registry_dns_zone_id" {
  description = "ID of the Container Registry private DNS zone"
  value       = azurerm_private_dns_zone.container_registry.id
}
