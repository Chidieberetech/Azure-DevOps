#================================================
# MODULE INPUT VARIABLES
#================================================

#================================================
# CORE CONFIGURATION
#================================================

variable "environment" {
  description = "The environment name (e.g., dev, int, prod)"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "location_secondary" {
  description = "Secondary Azure region for geo-replication"
  type        = string
  default     = "North Europe"
}

#================================================
# NETWORK CONFIGURATION
#================================================

variable "enable_firewall" {
  description = "Enable Azure Firewall"
  type        = bool
  default     = false
}

variable "enable_bastion" {
  description = "Enable Azure Bastion"
  type        = bool
  default     = false
}

variable "enable_private_dns" {
  description = "Enable Private DNS zones"
  type        = bool
  default     = true
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
  default     = true
}

variable "spoke_count" {
  description = "Number of spoke networks to create"
  type        = number
  default     = 1
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "vpn_gateway_sku" {
  description = "VPN Gateway SKU"
  type        = string
  default     = "VpnGw1"
}

variable "enable_expressroute_gateway" {
  description = "Enable ExpressRoute Gateway"
  type        = bool
  default     = false
}

variable "expressroute_gateway_sku" {
  description = "ExpressRoute Gateway SKU"
  type        = string
  default     = "Standard"
}

variable "enable_app_gateway" {
  description = "Enable Application Gateway"
  type        = bool
  default     = false
}

variable "app_gateway_sku_name" {
  description = "Application Gateway SKU name"
  type        = string
  default     = "Standard_v2"
}

variable "app_gateway_sku_tier" {
  description = "Application Gateway SKU tier"
  type        = string
  default     = "Standard_v2"
}

variable "app_gateway_capacity" {
  description = "Application Gateway capacity"
  type        = number
  default     = 2
}

#================================================
# COMPUTE CONFIGURATION
#================================================

variable "vm_size" {
  description = "Virtual machine size"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for virtual machines"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for virtual machines"
  type        = string
  sensitive   = true
}

variable "enable_vm_auto_shutdown" {
  description = "Enable auto-shutdown for VMs"
  type        = bool
  default     = false
}

variable "vm_shutdown_time" {
  description = "Time for VM auto-shutdown (UTC)"
  type        = string
  default     = "1900"
}

variable "enable_vm_monitoring" {
  description = "Enable VM monitoring and diagnostics"
  type        = bool
  default     = true
}

variable "vm_cpu_alert_threshold" {
  description = "CPU alert threshold percentage for VMs"
  type        = number
  default     = 80
}

variable "vm_memory_alert_threshold_bytes" {
  description = "Memory alert threshold in bytes for VMs"
  type        = number
  default     = 1073741824 # 1GB
}

#================================================
# STORAGE CONFIGURATION
#================================================

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "storage_availability_threshold" {
  description = "Storage availability alert threshold percentage"
  type        = number
  default     = 99
}

variable "enable_data_lake" {
  description = "Enable Data Lake Storage"
  type        = bool
  default     = false
}

variable "data_lake_replication_type" {
  description = "Data Lake replication type"
  type        = string
  default     = "LRS"
}

variable "enable_storage_sync" {
  description = "Enable Azure File Sync"
  type        = bool
  default     = false
}

variable "enable_migration_storage" {
  description = "Enable migration storage account"
  type        = bool
  default     = false
}

#================================================
# DATABASE CONFIGURATION
#================================================

variable "enable_sql_database" {
  description = "Enable SQL Database"
  type        = bool
  default     = false
}

variable "sql_database_sku" {
  description = "SQL Database SKU"
  type        = string
  default     = "Basic"
}

variable "enable_cosmos_db" {
  description = "Enable Cosmos DB"
  type        = bool
  default     = false
}

variable "enable_database_alerts" {
  description = "Enable database monitoring alerts"
  type        = bool
  default     = true
}

variable "sql_cpu_alert_threshold" {
  description = "SQL CPU alert threshold percentage"
  type        = number
  default     = 80
}

variable "sql_storage_alert_threshold" {
  description = "SQL storage alert threshold percentage"
  type        = number
  default     = 80
}

variable "enable_synapse" {
  description = "Enable Azure Synapse Analytics"
  type        = bool
  default     = false
}

variable "enable_synapse_sql_pool" {
  description = "Enable Synapse SQL Pool"
  type        = bool
  default     = false
}

variable "enable_synapse_spark_pool" {
  description = "Enable Synapse Spark Pool"
  type        = bool
  default     = false
}

variable "synapse_sql_admin_login" {
  description = "Synapse SQL admin login"
  type        = string
  default     = "sqladmin"
}

variable "synapse_sql_admin_password" {
  description = "Synapse SQL admin password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "synapse_sql_pool_sku" {
  description = "Synapse SQL Pool SKU"
  type        = string
  default     = "DW100c"
}

variable "synapse_spark_node_size" {
  description = "Synapse Spark node size"
  type        = string
  default     = "Small"
}

variable "synapse_spark_node_count" {
  description = "Synapse Spark node count"
  type        = number
  default     = 3
}

variable "synapse_spark_min_nodes" {
  description = "Synapse Spark minimum nodes for autoscale"
  type        = number
  default     = 3
}

variable "synapse_spark_max_nodes" {
  description = "Synapse Spark maximum nodes for autoscale"
  type        = number
  default     = 10
}

variable "synapse_spark_auto_pause_delay" {
  description = "Synapse Spark auto-pause delay in minutes"
  type        = number
  default     = 15
}

#================================================
# MONITORING CONFIGURATION
#================================================

variable "enable_monitoring" {
  description = "Enable monitoring resources"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "log_analytics_sku" {
  description = "Log Analytics workspace SKU"
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_daily_quota_gb" {
  description = "Log Analytics daily quota in GB"
  type        = number
  default     = -1
}

variable "log_analytics_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 30
}

variable "enable_application_insights" {
  description = "Enable Application Insights"
  type        = bool
  default     = false
}

variable "application_insights_type" {
  description = "Application Insights type"
  type        = string
  default     = "web"
}

variable "enable_monitoring_workbooks" {
  description = "Enable Azure Monitor Workbooks"
  type        = bool
  default     = false
}

#================================================
# SECURITY CONFIGURATION
#================================================

variable "enable_key_vault" {
  description = "Enable Key Vault"
  type        = bool
  default     = true
}

variable "key_vault_sku" {
  description = "Key Vault SKU"
  type        = string
  default     = "standard"
}

variable "enable_key_vault_soft_delete" {
  description = "Enable Key Vault soft delete"
  type        = bool
  default     = true
}

variable "keyvault_availability_threshold" {
  description = "Key Vault availability alert threshold percentage"
  type        = number
  default     = 99
}

variable "enable_security_center" {
  description = "Enable Security Center"
  type        = bool
  default     = false
}

variable "enable_managed_identity" {
  description = "Enable Managed Identity"
  type        = bool
  default     = true
}

#================================================
# CONTAINERS CONFIGURATION
#================================================

variable "enable_containers" {
  description = "Enable container services"
  type        = bool
  default     = false
}

variable "enable_container_registry" {
  description = "Enable Azure Container Registry"
  type        = bool
  default     = false
}

variable "container_registry_sku" {
  description = "Container Registry SKU"
  type        = string
  default     = "Basic"
}

variable "container_registry_admin_enabled" {
  description = "Enable Container Registry admin user"
  type        = bool
  default     = false
}

variable "enable_container_registry_georeplication" {
  description = "Enable Container Registry geo-replication"
  type        = bool
  default     = false
}

variable "enable_aks" {
  description = "Enable Azure Kubernetes Service"
  type        = bool
  default     = false
}

variable "aks_vm_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "aks_node_count" {
  description = "AKS node count"
  type        = number
  default     = 3
}

variable "aks_kubernetes_version" {
  description = "AKS Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "aks_enable_auto_scaling" {
  description = "Enable AKS auto-scaling"
  type        = bool
  default     = false
}

variable "aks_min_count" {
  description = "AKS minimum node count for auto-scaling"
  type        = number
  default     = 1
}

variable "aks_max_count" {
  description = "AKS maximum node count for auto-scaling"
  type        = number
  default     = 5
}

variable "aks_max_pods" {
  description = "Maximum pods per AKS node"
  type        = number
  default     = 30
}

variable "aks_os_disk_size" {
  description = "AKS OS disk size in GB"
  type        = number
  default     = 50
}

variable "enable_aks_rbac" {
  description = "Enable AKS RBAC"
  type        = bool
  default     = true
}

variable "enable_aks_monitoring" {
  description = "Enable AKS monitoring"
  type        = bool
  default     = true
}

variable "enable_aks_azure_policy" {
  description = "Enable AKS Azure Policy"
  type        = bool
  default     = false
}

variable "enable_aks_http_application_routing" {
  description = "Enable AKS HTTP application routing"
  type        = bool
  default     = false
}

variable "enable_aks_vnet_integration" {
  description = "Enable AKS VNet integration"
  type        = bool
  default     = true
}

variable "aks_subnet_address_prefix" {
  description = "AKS subnet address prefix"
  type        = string
  default     = "10.1.2.0/24"
}

variable "aks_service_cidr" {
  description = "AKS service CIDR"
  type        = string
  default     = "10.250.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "AKS DNS service IP"
  type        = string
  default     = "10.250.0.10"
}

variable "aks_admin_group_object_ids" {
  description = "Azure AD group object IDs for AKS admins"
  type        = list(string)
  default     = []
}

variable "aks_availability_zones" {
  description = "AKS availability zones"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "enable_aks_spot_node_pool" {
  description = "Enable AKS spot node pool"
  type        = bool
  default     = false
}

variable "aks_spot_node_count" {
  description = "AKS spot node count"
  type        = number
  default     = 1
}

variable "aks_spot_vm_size" {
  description = "AKS spot node VM size"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "aks_spot_max_price" {
  description = "AKS spot max price (-1 for no max)"
  type        = number
  default     = -1
}

variable "aks_cpu_alert_threshold" {
  description = "AKS CPU alert threshold percentage"
  type        = number
  default     = 80
}

variable "aks_memory_alert_threshold" {
  description = "AKS memory alert threshold percentage"
  type        = number
  default     = 80
}

variable "enable_container_instances" {
  description = "Enable Azure Container Instances"
  type        = bool
  default     = false
}

variable "container_instances_dns_name_label" {
  description = "Container Instances DNS name label"
  type        = string
  default     = ""
}

variable "container_instances_ip_address_type" {
  description = "Container Instances IP address type"
  type        = string
  default     = "Private"
}

variable "enable_container_instances_vnet_integration" {
  description = "Enable Container Instances VNet integration"
  type        = bool
  default     = true
}

variable "containers_subnet_address_prefix" {
  description = "Container Instances subnet address prefix"
  type        = string
  default     = "10.1.3.0/24"
}

variable "enable_container_apps" {
  description = "Enable Azure Container Apps"
  type        = bool
  default     = false
}

#================================================
# WEB & MOBILE CONFIGURATION
#================================================

variable "enable_app_service" {
  description = "Enable App Service"
  type        = bool
  default     = false
}

variable "app_service_plan_sku" {
  description = "App Service Plan SKU"
  type        = string
  default     = "B1"
}

variable "enable_function_app" {
  description = "Enable Function App"
  type        = bool
  default     = false
}

variable "enable_static_web_app" {
  description = "Enable Static Web App"
  type        = bool
  default     = false
}

variable "enable_cdn" {
  description = "Enable CDN"
  type        = bool
  default     = false
}

variable "enable_notification_hub" {
  description = "Enable Notification Hub"
  type        = bool
  default     = false
}

#================================================
# ANALYTICS CONFIGURATION
#================================================

variable "enable_analytics" {
  description = "Enable analytics services"
  type        = bool
  default     = false
}

variable "enable_data_factory" {
  description = "Enable Data Factory"
  type        = bool
  default     = false
}

#================================================
# AI/ML CONFIGURATION
#================================================

variable "enable_machine_learning" {
  description = "Enable Machine Learning workspace"
  type        = bool
  default     = false
}

variable "enable_cognitive_services" {
  description = "Enable Cognitive Services"
  type        = bool
  default     = false
}

variable "cognitive_services_sku" {
  description = "Cognitive Services SKU"
  type        = string
  default     = "S0"
}

variable "enable_search_service" {
  description = "Enable Azure Search Service"
  type        = bool
  default     = false
}

variable "search_service_sku" {
  description = "Search Service SKU"
  type        = string
  default     = "basic"
}

#================================================
# IOT CONFIGURATION
#================================================

variable "enable_iot_hub" {
  description = "Enable IoT Hub"
  type        = bool
  default     = false
}

variable "iot_hub_sku_name" {
  description = "IoT Hub SKU name"
  type        = string
  default     = "S1"
}

variable "iot_hub_capacity" {
  description = "IoT Hub capacity"
  type        = number
  default     = 1
}

variable "enable_iot_dps" {
  description = "Enable IoT Device Provisioning Service"
  type        = bool
  default     = false
}

variable "enable_iot_central" {
  description = "Enable IoT Central"
  type        = bool
  default     = false
}

variable "enable_digital_twins" {
  description = "Enable Azure Digital Twins"
  type        = bool
  default     = false
}

#================================================
# INTEGRATION CONFIGURATION
#================================================

variable "enable_logic_apps" {
  description = "Enable Logic Apps"
  type        = bool
  default     = false
}

variable "enable_service_bus" {
  description = "Enable Service Bus"
  type        = bool
  default     = false
}

variable "enable_event_grid" {
  description = "Enable Event Grid"
  type        = bool
  default     = false
}

variable "enable_api_management" {
  description = "Enable API Management"
  type        = bool
  default     = false
}

variable "api_management_sku" {
  description = "API Management SKU"
  type        = string
  default     = "Developer_1"
}

variable "api_management_publisher_name" {
  description = "API Management publisher name"
  type        = string
  default     = "Publisher"
}

variable "api_management_publisher_email" {
  description = "API Management publisher email"
  type        = string
  default     = "publisher@example.com"
}

variable "enable_relay" {
  description = "Enable Azure Relay"
  type        = bool
  default     = false
}

variable "enable_integration_servicebus" {
  description = "Enable integration Service Bus"
  type        = bool
  default     = false
}

variable "enable_integration_logic_apps" {
  description = "Enable integration Logic Apps"
  type        = bool
  default     = false
}

#================================================
# DEVOPS CONFIGURATION
#================================================

variable "enable_devops" {
  description = "Enable DevOps services"
  type        = bool
  default     = false
}

variable "enable_automation" {
  description = "Enable Automation Account"
  type        = bool
  default     = false
}

#================================================
# MIGRATION CONFIGURATION
#================================================

variable "enable_database_migration" {
  description = "Enable database migration"
  type        = bool
  default     = false
}

variable "enable_database_migration_service" {
  description = "Enable Database Migration Service"
  type        = bool
  default     = false
}

variable "enable_site_recovery" {
  description = "Enable Site Recovery"
  type        = bool
  default     = false
}

variable "enable_site_recovery_migration" {
  description = "Enable Site Recovery migration"
  type        = bool
  default     = false
}

variable "enable_app_migration" {
  description = "Enable app migration"
  type        = bool
  default     = false
}

variable "enable_migration_backup" {
  description = "Enable migration backup"
  type        = bool
  default     = false
}

variable "enable_import_export" {
  description = "Enable Import/Export service"
  type        = bool
  default     = false
}

#================================================
# IDENTITY CONFIGURATION
#================================================

variable "enable_aad_b2c" {
  description = "Enable Azure AD B2C"
  type        = bool
  default     = false
}

variable "enable_aad_ds" {
  description = "Enable Azure AD Domain Services"
  type        = bool
  default     = false
}

variable "enable_identity_keyvault" {
  description = "Enable identity Key Vault"
  type        = bool
  default     = false
}

variable "aad_ds_domain_name" {
  description = "Azure AD Domain Services domain name"
  type        = string
  default     = "example.com"
}

variable "aad_b2c_country_code" {
  description = "Azure AD B2C country code"
  type        = string
  default     = "US"
}

#================================================
# GOVERNANCE CONFIGURATION
#================================================

variable "enable_policy" {
  description = "Enable Azure Policy"
  type        = bool
  default     = false
}

variable "enable_management_group" {
  description = "Enable Management Groups"
  type        = bool
  default     = false
}

variable "enable_cost_monitoring" {
  description = "Enable cost monitoring"
  type        = bool
  default     = false
}

variable "enable_custom_roles" {
  description = "Enable custom RBAC roles"
  type        = bool
  default     = false
}

variable "enable_custom_governance_roles" {
  description = "Enable custom governance roles"
  type        = bool
  default     = false
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount"
  type        = number
  default     = 1000
}

variable "budget_alert_emails" {
  description = "Budget alert emails"
  type        = list(string)
  default     = []
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds"
  type        = list(number)
  default     = [80, 100, 120]
}

variable "budget_forecast_thresholds" {
  description = "Budget forecast thresholds"
  type        = list(number)
  default     = [100]
}

variable "enable_governance_monitoring" {
  description = "Enable governance monitoring"
  type        = bool
  default     = false
}

variable "enable_governance_alerts" {
  description = "Enable governance alerts"
  type        = bool
  default     = false
}

variable "governance_alert_email" {
  description = "Governance alert email"
  type        = string
  default     = ""
}

#================================================
# MIXED REALITY CONFIGURATION
#================================================

variable "enable_spatial_anchors" {
  description = "Enable Spatial Anchors"
  type        = bool
  default     = false
}

variable "enable_mixed_reality_storage" {
  description = "Enable mixed reality storage"
  type        = bool
  default     = false
}

variable "enable_mixed_reality_acr" {
  description = "Enable mixed reality container registry"
  type        = bool
  default     = false
}

variable "enable_mixed_reality_cdn" {
  description = "Enable mixed reality CDN"
  type        = bool
  default     = false
}

#================================================
# HYBRID & MULTI-CLOUD CONFIGURATION
#================================================

variable "enable_arc_kubernetes" {
  description = "Enable Arc-enabled Kubernetes"
  type        = bool
  default     = false
}

variable "arc_kubernetes_public_key" {
  description = "Arc Kubernetes public key"
  type        = string
  default     = ""
}

variable "enable_stack_hci" {
  description = "Enable Azure Stack HCI"
  type        = bool
  default     = false
}

#================================================
# OTHER SERVICES CONFIGURATION
#================================================

variable "enable_maps" {
  description = "Enable Azure Maps"
  type        = bool
  default     = false
}

variable "maps_sku_name" {
  description = "Azure Maps SKU"
  type        = string
  default     = "S0"
}

#================================================
# ALERTING CONFIGURATION
#================================================

variable "enable_infrastructure_alerts" {
  description = "Enable infrastructure alerts"
  type        = bool
  default     = true
}

variable "enable_application_alerts" {
  description = "Enable application alerts"
  type        = bool
  default     = false
}

variable "enable_security_alerts" {
  description = "Enable security alerts"
  type        = bool
  default     = false
}

variable "enable_advanced_alerting" {
  description = "Enable advanced alerting"
  type        = bool
  default     = false
}

variable "critical_alert_emails" {
  description = "Critical alert email addresses"
  type        = list(string)
  default     = []
}

variable "warning_alert_emails" {
  description = "Warning alert email addresses"
  type        = list(string)
  default     = []
}

variable "critical_alert_sms" {
  description = "Critical alert SMS numbers"
  type        = list(string)
  default     = []
}

variable "critical_alert_webhooks" {
  description = "Critical alert webhook URLs"
  type        = list(string)
  default     = []
}

variable "admin_phone_number" {
  description = "Admin phone number for alerts"
  type        = string
  default     = ""
}

variable "app_response_time_threshold_seconds" {
  description = "Application response time threshold in seconds"
  type        = number
  default     = 5
}

variable "app_error_rate_threshold" {
  description = "Application error rate threshold percentage"
  type        = number
  default     = 5
}

variable "admin_email_address" {
  description = "Admin email address for notifications"
  type        = string
  default     = "admin@example.com"
}

variable "activity_log_categories" {
  description = "Activity log categories to enable"
  type        = list(string)
  default     = ["Administrative", "Security", "ServiceHealth", "Alert", "Recommendation", "Policy", "Autoscale", "ResourceHealth"]
}

#================================================
# TAGGING CONFIGURATION
#================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

