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
  description = "Names of the spoke resource groups"
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

output "hub_address_space" {
  description = "Address space of the hub virtual network"
  value       = azurerm_virtual_network.hub.address_space
}

output "spoke_address_spaces" {
  description = "Address spaces of the spoke virtual networks"
  value       = azurerm_virtual_network.spokes[*].address_space
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

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion"
  value       = var.enable_bastion ? azurerm_public_ip.bastion[0].ip_address : null
}

output "firewall_id" {
  description = "ID of the Azure Firewall"
  value       = var.enable_firewall ? azurerm_firewall.main[0].id : null
}

output "bastion_id" {
  description = "ID of the Azure Bastion"
  value       = var.enable_bastion ? azurerm_bastion_host.main[0].id : null
}

#================================================
# COMPUTE OUTPUTS
#================================================

output "vm_ids" {
  description = "IDs of the virtual machines"
  value = {
    alpha = var.spoke_count >= 1 ? azurerm_windows_virtual_machine.spoke_alpha_vm[0].id : null
    beta  = var.spoke_count >= 2 ? azurerm_windows_virtual_machine.spoke_beta_vm[0].id : null
  }
}

output "vm_private_ips" {
  description = "Private IP addresses of the virtual machines"
  value = {
    alpha = var.spoke_count >= 1 ? azurerm_network_interface.spoke_alpha_vm[0].ip_configuration[0].private_ip_address : null
    beta  = var.spoke_count >= 2 ? azurerm_network_interface.spoke_beta_vm[0].ip_configuration[0].private_ip_address : null
  }
}

output "vm_names" {
  description = "Names of the virtual machines"
  value = {
    alpha = var.spoke_count >= 1 ? azurerm_windows_virtual_machine.spoke_alpha_vm[0].name : null
    beta  = var.spoke_count >= 2 ? azurerm_windows_virtual_machine.spoke_beta_vm[0].name : null
  }
}

#================================================
# STORAGE OUTPUTS
#================================================

output "storage_account_name" {
  description = "Name of the main storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID of the main storage account"
  value       = azurerm_storage_account.main.id
}

output "diagnostics_storage_account_name" {
  description = "Name of the diagnostics storage account"
  value       = azurerm_storage_account.diagnostics.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the main storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

#================================================
# KEY VAULT OUTPUTS
#================================================

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
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
# PRIVATE DNS OUTPUTS
#================================================

output "private_dns_zones" {
  description = "Private DNS zones created"
  value = var.enable_private_dns ? {
    key_vault    = azurerm_private_dns_zone.key_vault[0].name
    storage_blob = azurerm_private_dns_zone.storage_blob[0].name
    storage_file = azurerm_private_dns_zone.storage_file[0].name
    sql_database = var.enable_sql_database ? azurerm_private_dns_zone.sql_database[0].name : null
    cosmos_db    = var.enable_cosmos_db ? azurerm_private_dns_zone.cosmos_db[0].name : null
  } : null
}

#================================================
# SUBNET OUTPUTS
#================================================

output "hub_subnet_ids" {
  description = "IDs of hub subnets"
  value = {
    firewall           = azurerm_subnet.firewall.id
    bastion            = azurerm_subnet.bastion.id
    gateway            = azurerm_subnet.gateway.id
    shared_services    = azurerm_subnet.shared_services.id
    private_endpoint   = azurerm_subnet.hub_private_endpoint.id
  }
}

output "spoke_subnet_ids" {
  description = "IDs of spoke subnets"
  value = {
    alpha = var.spoke_count >= 1 ? {
      workload         = azurerm_subnet.spoke_alpha_workload[0].id
      vm               = azurerm_subnet.spoke_alpha_vm[0].id
      database         = azurerm_subnet.spoke_alpha_database[0].id
      private_endpoint = azurerm_subnet.spoke_alpha_private_endpoint[0].id
    } : null
    beta = var.spoke_count >= 2 ? {
      workload         = azurerm_subnet.spoke_beta_workload[0].id
      vm               = azurerm_subnet.spoke_beta_vm[0].id
      private_endpoint = azurerm_subnet.spoke_beta_private_endpoint[0].id
    } : null
  }
}

#================================================
# ROUTE TABLE OUTPUTS
#================================================

output "route_table_ids" {
  description = "IDs of the route tables"
  value       = azurerm_route_table.spoke_to_firewall[*].id
}

#================================================
# TAGS OUTPUT
#================================================

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

#================================================
# ANALYTICS OUTPUTS
#================================================

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = var.enable_analytics ? azurerm_log_analytics_workspace.main[0].id : null
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = var.enable_analytics ? azurerm_log_analytics_workspace.main[0].name : null
}

output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = var.enable_analytics && var.enable_application_insights ? azurerm_application_insights.main[0].id : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = var.enable_analytics && var.enable_application_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = var.enable_analytics && var.enable_application_insights ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

output "data_factory_id" {
  description = "ID of the Data Factory"
  value       = var.enable_analytics && var.enable_data_factory ? azurerm_data_factory.main[0].id : null
}

output "data_factory_name" {
  description = "Name of the Data Factory"
  value       = var.enable_analytics && var.enable_data_factory ? azurerm_data_factory.main[0].name : null
}

output "data_lake_storage_account_id" {
  description = "ID of the Data Lake Storage account"
  value       = var.enable_analytics && var.enable_data_lake ? azurerm_storage_account.data_lake[0].id : null
}

output "data_lake_storage_account_name" {
  description = "Name of the Data Lake Storage account"
  value       = var.enable_analytics && var.enable_data_lake ? azurerm_storage_account.data_lake[0].name : null
}

output "data_lake_primary_dfs_endpoint" {
  description = "Primary DFS endpoint of the Data Lake Storage account"
  value       = var.enable_analytics && var.enable_data_lake ? azurerm_storage_account.data_lake[0].primary_dfs_endpoint : null
}

output "synapse_workspace_id" {
  description = "ID of the Synapse Analytics workspace"
  value       = var.enable_analytics && var.enable_synapse ? azurerm_synapse_workspace.main[0].id : null
}

output "synapse_workspace_name" {
  description = "Name of the Synapse Analytics workspace"
  value       = var.enable_analytics && var.enable_synapse ? azurerm_synapse_workspace.main[0].name : null
}

output "synapse_sql_pool_id" {
  description = "ID of the Synapse SQL Pool"
  value       = var.enable_analytics && var.enable_synapse && var.enable_synapse_sql_pool ? azurerm_synapse_sql_pool.main[0].id : null
}

output "synapse_spark_pool_id" {
  description = "ID of the Synapse Spark Pool"
  value       = var.enable_analytics && var.enable_synapse && var.enable_synapse_spark_pool ? azurerm_synapse_spark_pool.main[0].id : null
}

#================================================
# CONTAINER OUTPUTS
#================================================

output "container_registry_id" {
  description = "ID of the Azure Container Registry"
  value       = var.enable_containers && var.enable_container_registry ? azurerm_container_registry.main[0].id : null
}

output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = var.enable_containers && var.enable_container_registry ? azurerm_container_registry.main[0].name : null
}

output "container_registry_login_server" {
  description = "Login server of the Azure Container Registry"
  value       = var.enable_containers && var.enable_container_registry ? azurerm_container_registry.main[0].login_server : null
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = var.enable_containers && var.enable_aks ? azurerm_kubernetes_cluster.main[0].id : null
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = var.enable_containers && var.enable_aks ? azurerm_kubernetes_cluster.main[0].name : null
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = var.enable_containers && var.enable_aks ? azurerm_kubernetes_cluster.main[0].fqdn : null
}

output "aks_kube_config" {
  description = "Kubernetes configuration for the AKS cluster"
  value       = var.enable_containers && var.enable_aks ? azurerm_kubernetes_cluster.main[0].kube_config_raw : null
  sensitive   = true
}

output "aks_cluster_identity" {
  description = "Identity of the AKS cluster"
  value       = var.enable_containers && var.enable_aks ? azurerm_kubernetes_cluster.main[0].identity : null
}

output "container_instances_group_id" {
  description = "ID of the Container Instances group"
  value       = var.enable_containers && var.enable_container_instances ? azurerm_container_group.main[0].id : null
}

output "container_instances_fqdn" {
  description = "FQDN of the Container Instances group"
  value       = var.enable_containers && var.enable_container_instances ? azurerm_container_group.main[0].fqdn : null
}

output "container_app_environment_id" {
  description = "ID of the Container Apps environment"
  value       = var.enable_containers && var.enable_container_apps ? azurerm_container_app_environment.main[0].id : null
}

output "container_app_id" {
  description = "ID of the Container App"
  value       = var.enable_containers && var.enable_container_apps ? azurerm_container_app.main[0].id : null
}

output "container_app_url" {
  description = "URL of the Container App"
  value       = var.enable_containers && var.enable_container_apps ? azurerm_container_app.main[0].latest_revision_fqdn : null
}

#================================================
# CONTAINER NETWORKING OUTPUTS
#================================================

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = var.enable_containers && var.enable_aks && var.enable_aks_vnet_integration ? azurerm_subnet.hub_aks[0].id : null
}

output "containers_subnet_id" {
  description = "ID of the containers subnet"
  value       = var.enable_containers && var.enable_container_instances && var.enable_container_instances_vnet_integration ? azurerm_subnet.hub_containers[0].id : null
}
