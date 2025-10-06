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

output "management_resource_group_name" {
  description = "Name of the management resource group"
  value       = azurerm_resource_group.management.name
}

output "management_resource_group_id" {
  description = "ID of the management resource group"
  value       = azurerm_resource_group.management.id
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

output "premium_storage_account_id" {
  description = "ID of the premium storage account"
  value       = var.enable_premium_storage ? azurerm_storage_account.premium[0].id : null
}

output "data_lake_storage_account_id" {
  description = "ID of the Data Lake Storage account"
  value       = var.enable_data_lake_storage ? azurerm_storage_account.datalake[0].id : null
}

#================================================
# KEY VAULT OUTPUTS
#================================================

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.main.id : null
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.main.name : null
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.main.vault_uri : null
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
    aks               = var.enable_containers && var.enable_aks && var.enable_aks_vnet_integration ? azurerm_subnet.hub_aks[0].id : null
    containers        = var.enable_containers && var.enable_container_instances && var.enable_container_instances_vnet_integration ? azurerm_subnet.hub_containers[0].id : null
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
# MONITORING OUTPUTS
#================================================

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].name : null
}

output "log_analytics_workspace_workspace_id" {
  description = "Workspace ID of the Log Analytics workspace"
  value       = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].workspace_id : null
}

output "log_analytics_primary_shared_key" {
  description = "Primary shared key for Log Analytics workspace"
  value       = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].primary_shared_key : null
  sensitive   = true
}

output "action_group_id" {
  description = "ID of the Monitor Action Group"
  value       = var.enable_monitoring ? azurerm_monitor_action_group.main[0].id : null
}

output "critical_action_group_id" {
  description = "ID of the Critical Monitor Action Group"
  value       = var.enable_monitoring && var.enable_advanced_alerting ? azurerm_monitor_action_group.critical[0].id : null
}

output "warning_action_group_id" {
  description = "ID of the Warning Monitor Action Group"
  value       = var.enable_monitoring && var.enable_advanced_alerting ? azurerm_monitor_action_group.warning[0].id : null
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
  description = "Login server URL for the Azure Container Registry"
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
  description = "Kubernetes configuration for AKS cluster"
  value       = var.enable_containers && var.enable_aks ? azurerm_kubernetes_cluster.main[0].kube_config_raw : null
  sensitive   = true
}

output "container_app_environment_id" {
  description = "ID of the Container App Environment"
  value       = var.enable_containers && var.enable_container_apps ? azurerm_container_app_environment.main[0].id : null
}

#================================================
# AI/ML OUTPUTS
#================================================

output "cognitive_services_id" {
  description = "ID of the Cognitive Services account"
  value       = var.enable_cognitive_services ? azurerm_cognitive_account.main[0].id : null
}

output "cognitive_services_endpoint" {
  description = "Endpoint of the Cognitive Services account"
  value       = var.enable_cognitive_services ? azurerm_cognitive_account.main[0].endpoint : null
}

output "cognitive_services_key" {
  description = "Primary key for Cognitive Services account"
  value       = var.enable_cognitive_services ? azurerm_cognitive_account.main[0].primary_access_key : null
  sensitive   = true
}

output "machine_learning_workspace_id" {
  description = "ID of the Machine Learning workspace"
  value       = var.enable_machine_learning ? azurerm_machine_learning_workspace.main[0].id : null
}

output "machine_learning_workspace_name" {
  description = "Name of the Machine Learning workspace"
  value       = var.enable_machine_learning ? azurerm_machine_learning_workspace.main[0].name : null
}

#================================================
# IOT OUTPUTS
#================================================

output "iot_hub_id" {
  description = "ID of the IoT Hub"
  value       = var.enable_iot_hub ? azurerm_iothub.main[0].id : null
}

output "iot_hub_name" {
  description = "Name of the IoT Hub"
  value       = var.enable_iot_hub ? azurerm_iothub.main[0].name : null
}

output "iot_hub_hostname" {
  description = "Hostname of the IoT Hub"
  value       = var.enable_iot_hub ? azurerm_iothub.main[0].hostname : null
}

output "iot_dps_id" {
  description = "ID of the IoT Device Provisioning Service"
  value       = var.enable_iot_dps ? azurerm_iothub_dps.main[0].id : null
}

output "digital_twins_id" {
  description = "ID of the Digital Twins instance"
  value       = var.enable_digital_twins ? azurerm_digital_twins_instance.main[0].id : null
}

output "digital_twins_host_name" {
  description = "Host name of the Digital Twins instance"
  value       = var.enable_digital_twins ? azurerm_digital_twins_instance.main[0].host_name : null
}

#================================================
# WEB & MOBILE OUTPUTS
#================================================

output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = var.enable_app_service ? azurerm_service_plan.main[0].id : null
}

output "web_app_id" {
  description = "ID of the Web App"
  value       = var.enable_app_service ? azurerm_linux_web_app.main[0].id : null
}

output "web_app_url" {
  description = "Default hostname of the Web App"
  value       = var.enable_app_service ? "https://${azurerm_linux_web_app.main[0].default_hostname}" : null
}

output "function_app_id" {
  description = "ID of the Function App"
  value       = var.enable_function_app ? azurerm_linux_function_app.main[0].id : null
}

output "static_web_app_id" {
  description = "ID of the Static Web App"
  value       = var.enable_static_web_app ? azurerm_static_web_app.main[0].id : null
}

output "static_web_app_url" {
  description = "Default hostname of the Static Web App"
  value       = var.enable_static_web_app ? azurerm_static_web_app.main[0].default_host_name : null
}

output "cdn_profile_id" {
  description = "ID of the CDN Profile"
  value       = var.enable_cdn ? azurerm_cdn_profile.main[0].id : null
}

output "cdn_endpoint_url" {
  description = "URL of the CDN Endpoint"
  value       = var.enable_cdn ? azurerm_cdn_endpoint.main[0].fqdn : null
}

#================================================
# DEVOPS OUTPUTS
#================================================

output "devops_container_registry_id" {
  description = "ID of the DevOps Container Registry"
  value       = var.enable_devops ? azurerm_container_registry.devops[0].id : null
}

output "devops_storage_account_id" {
  description = "ID of the DevOps Storage Account"
  value       = var.enable_devops ? azurerm_storage_account.devops[0].id : null
}

output "devops_key_vault_id" {
  description = "ID of the DevOps Key Vault"
  value       = var.enable_devops ? azurerm_key_vault.devops[0].id : null
}

output "app_configuration_id" {
  description = "ID of the App Configuration service"
  value       = var.enable_devops ? azurerm_app_configuration.devops[0].id : null
}

output "servicebus_namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = var.enable_devops ? azurerm_servicebus_namespace.devops[0].id : null
}

#================================================
# IDENTITY OUTPUTS
#================================================

output "managed_identity_id" {
  description = "ID of the User Assigned Managed Identity"
  value       = var.enable_managed_identity ? azurerm_user_assigned_identity.main[0].id : null
}

output "managed_identity_client_id" {
  description = "Client ID of the User Assigned Managed Identity"
  value       = var.enable_managed_identity ? azurerm_user_assigned_identity.main[0].client_id : null
}

output "managed_identity_principal_id" {
  description = "Principal ID of the User Assigned Managed Identity"
  value       = var.enable_managed_identity ? azurerm_user_assigned_identity.main[0].principal_id : null
}

#================================================
# COMMON TAGS AND ENVIRONMENT
#================================================

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "location" {
  description = "Primary Azure region"
  value       = var.location
}

output "location_secondary" {
  description = "Secondary Azure region"
  value       = var.location_secondary
}

output "resource_prefix" {
  description = "Resource naming prefix"
  value       = local.resource_prefix
}

#================================================
# ALERT AND MONITORING OUTPUTS
#================================================

output "monitoring_alerts_summary" {
  description = "Summary of configured monitoring alerts"
  value = {
    infrastructure_alerts = var.enable_infrastructure_alerts
    application_alerts   = var.enable_application_alerts
    database_alerts      = var.enable_database_alerts
    security_alerts      = var.enable_security_alerts
    cost_monitoring      = var.enable_cost_monitoring
    vm_monitoring        = var.enable_vm_monitoring
  }
}

output "alert_thresholds" {
  description = "Configured alert thresholds"
  value = {
    vm_cpu_threshold           = var.vm_cpu_alert_threshold
    storage_availability       = var.storage_availability_threshold
    keyvault_availability      = var.keyvault_availability_threshold
    app_response_time         = var.app_response_time_threshold_seconds
    sql_cpu_threshold         = var.sql_cpu_alert_threshold
    aks_cpu_threshold         = var.aks_cpu_alert_threshold
    monthly_budget            = var.monthly_budget_amount
  }
}

#================================================
# NETWORK WATCHER AND SECURITY
#================================================

output "network_watcher_id" {
  description = "ID of the Network Watcher"
  value       = azurerm_network_watcher.main.id
}

output "private_endpoint_summary" {
  description = "Summary of private endpoints deployed"
  value = {
    key_vault          = var.enable_private_dns ? "enabled" : "disabled"
    storage_blob       = var.spoke_count >= 1 ? "enabled" : "disabled"
    storage_file       = var.spoke_count >= 1 ? "enabled" : "disabled"
    container_registry = var.enable_containers && var.enable_container_registry && var.container_registry_sku == "Premium" && var.enable_private_endpoints ? "enabled" : "disabled"
    iot_hub           = var.enable_iot_hub ? "enabled" : "disabled"
  }
}

#================================================
# INFRASTRUCTURE SUMMARY
#================================================

output "infrastructure_summary" {
  description = "Comprehensive summary of deployed infrastructure"
  value = {
    environment    = var.environment
    location       = var.location
    resource_count = {
      resource_groups = 1 + var.spoke_count + 1  # hub + spokes + management
      vnets          = 1 + var.spoke_count       # hub + spoke vnets
      subnets        = 5 + (var.spoke_count * 4) # hub subnets + spoke subnets
    }
    services = {
      compute = {
        vms_deployed     = var.spoke_count
        aks_enabled      = var.enable_containers && var.enable_aks
        containers       = var.enable_containers
      }
      networking = {
        firewall_enabled = var.enable_firewall
        bastion_enabled  = var.enable_bastion
        private_dns      = var.enable_private_dns
        vpn_gateway      = var.enable_vpn_gateway
        expressroute     = var.enable_expressroute_gateway
      }
      data = {
        sql_database     = var.enable_sql_database
        cosmos_db        = var.enable_cosmos_db
        storage_accounts = 2 + (var.enable_premium_storage ? 1 : 0) + (var.enable_data_lake_storage ? 1 : 0)
        data_factory     = var.enable_data_factory
        synapse          = var.enable_synapse
      }
      monitoring = {
        log_analytics    = var.enable_monitoring
        alerts_enabled   = var.enable_infrastructure_alerts
        cost_monitoring  = var.enable_cost_monitoring
        security_center  = var.enable_security_center
      }
      ai_ml = {
        cognitive_services = var.enable_cognitive_services
        machine_learning   = var.enable_machine_learning
      }
      iot = {
        iot_hub          = var.enable_iot_hub
        iot_dps          = var.enable_iot_dps
        digital_twins    = var.enable_digital_twins
        iot_central      = var.enable_iot_central
      }
      web_mobile = {
        app_service      = var.enable_app_service
        function_app     = var.enable_function_app
        static_web_app   = var.enable_static_web_app
        cdn              = var.enable_cdn
      }
    }
  }
}
