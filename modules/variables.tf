# Variables for TRL Hub and Spoke Infrastructure

#================================================
# ENVIRONMENT CONFIGURATION
#================================================

# Environment variable with validation
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

#================================================
# CORE CONFIGURATION
#================================================
# Azure region variable
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"

  # Validation for primary location to be within approved regions
  validation {
    condition = contains([
      "West Europe",
      "East US",
      "East US 2",
      "Central US",
      "North Europe",
      "UK South",
      "Southeast Asia"
    ], var.location)
    error_message = "Location must be one of the approved regions."
  }
}

# Secondary location for geo-redundant resources
variable "location_secondary" {
  description = "Secondary Azure region for geo-redundant resources"
  type        = string
  default     = "North Europe"

  # Validation to ensure secondary location is different from primary and within approved regions
  validation {
    condition = var.location != var.location_secondary && contains([
      "West Europe",
      "East US",
      "East US 2",
      "Central US",
      "North Europe",
      "UK South",
      "Southeast Asia"
    ], var.location_secondary)
    error_message = "Secondary location must be different from primary location and one of the approved regions."
  }
}

# Azure subscription ID variable
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

#================================================
# HUB AND SPOKE CONFIGURATION
#================================================

# Number of spoke networks to create
variable "spoke_count" {
  description = "Number of spoke networks to create"
  type        = number
  default     = 2
  validation {
    condition = var.spoke_count >= 0 && var.spoke_count <= 3
    error_message = "Spoke count must be between 0 and 3."
  }
}

#================================================
# NETWORK CONFIGURATION
#================================================

# Enable DDoS Protection
variable "enable_ddos_protection" {
  description = "Enable DDoS Protection"
  type        = bool
  default     = false
}

# Enable Azure Firewall
variable "enable_firewall" {
  description = "Enable Azure Firewall deployment"
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Enable Azure Bastion deployment"
  type        = bool
  default     = true
}

variable "enable_private_dns" {
  description = "Enable private DNS zones"
  type        = bool
  default     = true
}

#================================================
# COMPUTE CONFIGURATION
#================================================

variable "vm_size" {
  description = "Size of the virtual machines (Free tier compatible)"
  type        = string
  default     = "Standard_B1s"
  validation {
    condition = contains([
      "Standard_B1s",
      "Standard_B2s",
      "Standard_D2s_v3"
    ], var.vm_size)
    error_message = "VM size must be from the approved list for free tier compatibility."
  }
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureadmin"
}

variable "enable_vm_auto_shutdown" {
  description = "Enable automatic VM shutdown for cost optimization"
  type        = bool
  default     = true
}

variable "vm_shutdown_time" {
  description = "Time to automatically shutdown VMs (24-hour format)"
  type        = string
  default     = "1900"
}

#================================================
# STORAGE CONFIGURATION
#================================================

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
  validation {
    condition = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be Standard or Premium."
  }
}

variable "storage_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
  validation {
    condition = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage_replication_type)
    error_message = "Storage replication type must be LRS, GRS, RAGRS, or ZRS."
  }
}

#================================================
# KEY VAULT CONFIGURATION
#================================================

variable "key_vault_sku" {
  description = "Key Vault SKU"
  type        = string
  default     = "standard"
  validation {
    condition = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "Key Vault SKU must be standard or premium."
  }
}

variable "enable_key_vault_soft_delete" {
  description = "Enable Key Vault soft delete"
  type        = bool
  default     = true
}

#================================================
# DATABASE CONFIGURATION
#================================================

variable "enable_sql_database" {
  description = "Enable SQL Database deployment"
  type        = bool
  default     = false
}

variable "sql_database_sku" {
  description = "SQL Database SKU"
  type        = string
  default     = "S0"
  validation {
    condition = contains(["Basic", "S0", "S1", "S2"], var.sql_database_sku)
    error_message = "SQL Database SKU must be Basic, S0, S1, or S2 for free tier compatibility."
  }
}

variable "enable_cosmos_db" {
  description = "Enable Cosmos DB deployment"
  type        = bool
  default     = false
}

#================================================
# MONITORING AND LOGGING
#================================================

variable "enable_monitoring" {
  description = "Enable Azure Monitor and Log Analytics"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
  validation {
    condition = var.log_retention_days >= 30 && var.log_retention_days <= 365
    error_message = "Log retention must be between 30 and 365 days."
  }
}

#================================================
# SECURITY CONFIGURATION
#================================================

variable "enable_security_center" {
  description = "Enable Azure Security Center"
  type        = bool
  default     = true
}

variable "security_contact_email" {
  description = "Email address for security alerts"
  type        = string
  default     = ""
}

#================================================
# BACKUP CONFIGURATION
#================================================

variable "enable_backup" {
  description = "Enable Azure Backup for VMs"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

#================================================
# TAGGING
#================================================

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

#================================================
# AI + MACHINE LEARNING CONFIGURATION
#================================================

variable "enable_cognitive_services" {
  description = "Enable Azure Cognitive Services"
  type        = bool
  default     = false
}

variable "cognitive_services_sku" {
  description = "SKU for Cognitive Services"
  type        = string
  default     = "S0"
}

variable "enable_machine_learning" {
  description = "Enable Azure Machine Learning"
  type        = bool
  default     = false
}

#================================================
# ANALYTICS CONFIGURATION
#================================================

variable "enable_synapse_analytics" {
  description = "Enable Azure Synapse Analytics"
  type        = bool
  default     = false
}

variable "enable_data_factory" {
  description = "Enable Azure Data Factory"
  type        = bool
  default     = false
}

variable "enable_event_hub" {
  description = "Enable Azure Event Hub"
  type        = bool
  default     = false
}

variable "enable_stream_analytics" {
  description = "Enable Azure Stream Analytics"
  type        = bool
  default     = false
}

#================================================
# CONTAINER CONFIGURATION
#================================================

variable "enable_container_registry" {
  description = "Enable Azure Container Registry"
  type        = bool
  default     = false
}

variable "container_registry_sku" {
  description = "SKU for Container Registry"
  type        = string
  default     = "Premium"
}

variable "container_registry_replications" {
  description = "List of regions for Container Registry geo-replication"
  type        = list(string)
  default     = []
}

variable "enable_aks" {
  description = "Enable Azure Kubernetes Service"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.27.3"
}

variable "aks_node_count" {
  description = "Number of nodes in AKS default node pool"
  type        = number
  default     = 2
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "enable_container_instances" {
  description = "Enable Azure Container Instances"
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

#================================================
# GENERAL SERVICES CONFIGURATION
#================================================

variable "enable_logic_apps" {
  description = "Enable Azure Logic Apps"
  type        = bool
  default     = false
}

variable "enable_automation" {
  description = "Enable Azure Automation"
  type        = bool
  default     = false
}

variable "enable_service_bus" {
  description = "Enable Service Bus"
  type        = bool
  default     = false
}
variable "service_bus_sku" {
  description = "SKU for Service Bus"
  type        = string
  default     = "Standard"
}

#================================================
# HYBRID + MULTICLOUD CONFIGURATION
#================================================

variable "enable_arc_kubernetes" {
  description = "Enable Azure Arc for Kubernetes"
  type        = bool
  default     = false
}

variable "arc_kubernetes_public_key" {
  description = "Public key certificate for Arc Kubernetes"
  type        = string
  default     = ""
}

variable "enable_site_recovery" {
  description = "Enable Site Recovery for hybrid DR"
  type        = bool
  default     = false
}

variable "enable_stack_hci" {
  description = "Enable Azure Stack HCI resources"
  type        = bool
  default     = false
}

variable "enable_database_migration" {
  description = "Enable Database Migration Service"
  type        = bool
  default     = false
}

variable "enable_azure_migrate" {
  description = "Enable Azure Migrate"
  type        = bool
  default     = false
}

variable "enable_storage_sync" {
  description = "Enable Storage Sync for hybrid storage"
  type        = bool
  default     = false
}

variable "enable_expressroute_gateway" {
  description = "Enable ExpressRoute Gateway"
  type        = bool
  default     = false
}

variable "expressroute_gateway_sku" {
  description = "SKU for ExpressRoute Gateway"
  type        = string
  default     = "Standard"
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "vpn_gateway_sku" {
  description = "SKU for VPN Gateway"
  type        = string
  default     = "VpnGw1"
}

#================================================
# IDENTITY CONFIGURATION
#================================================

variable "enable_aad_ds" {
  description = "Enable Azure Active Directory Domain Services"
  type        = bool
  default     = false
}

variable "aad_ds_domain_name" {
  description = "Domain name for AAD DS"
  type        = string
  default     = "trl.local"
}

variable "enable_managed_identity" {
  description = "Enable User Assigned Managed Identity"
  type        = bool
  default     = false
}

variable "enable_aad_b2c" {
  description = "Enable Azure AD B2C"
  type        = bool
  default     = false
}

variable "aad_b2c_country_code" {
  description = "Country code for AAD B2C"
  type        = string
  default     = "US"
}

variable "enable_identity_keyvault" {
  description = "Enable dedicated Key Vault for Identity"
  type        = bool
  default     = false
}

variable "enable_custom_roles" {
  description = "Enable custom role definitions"
  type        = bool
  default     = false
}

#================================================
# INTEGRATION CONFIGURATION
#================================================

variable "enable_integration_servicebus" {
  description = "Enable Service Bus for integration"
  type        = bool
  default     = false
}

variable "enable_event_grid" {
  description = "Enable Event Grid"
  type        = bool
  default     = false
}

variable "enable_integration_logic_apps" {
  description = "Enable Logic Apps for integration"
  type        = bool
  default     = false
}

variable "enable_app_gateway" {
  description = "Enable Application Gateway"
  type        = bool
  default     = false
}

variable "app_gateway_sku_name" {
  description = "SKU name for Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "app_gateway_sku_tier" {
  description = "SKU tier for Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "app_gateway_capacity" {
  description = "Capacity for Application Gateway"
  type        = number
  default     = 2
}

variable "enable_relay" {
  description = "Enable Azure Relay"
  type        = bool
  default     = false
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
  description = "SKU name for IoT Hub"
  type        = string
  default     = "S1"
}

variable "iot_hub_capacity" {
  description = "Capacity for IoT Hub"
  type        = number
  default     = 1
}

variable "enable_iot_dps" {
  description = "Enable IoT Device Provisioning Service"
  type        = bool
  default     = false
}

variable "enable_digital_twins" {
  description = "Enable Azure Digital Twins"
  type        = bool
  default     = false
}

variable "enable_time_series_insights" {
  description = "Enable Time Series Insights"
  type        = bool
  default     = false
}

variable "enable_iot_central" {
  description = "Enable IoT Central"
  type        = bool
  default     = false
}

variable "enable_maps" {
  description = "Enable Azure Maps"
  type        = bool
  default     = false
}

variable "maps_sku_name" {
  description = "SKU for Azure Maps"
  type        = string
  default     = "S1"
}

#================================================
# MANAGEMENT AND GOVERNANCE CONFIGURATION
#================================================

variable "enable_policy" {
  description = "Enable Azure Policy assignments"
  type        = bool
  default     = false
}

variable "enable_management_group" {
  description = "Enable Management Groups"
  type        = bool
  default     = false
}

variable "enable_blueprint" {
  description = "Enable Azure Blueprints"
  type        = bool
  default     = false
}

variable "blueprint_version_id" {
  description = "Version ID for Blueprint assignment"
  type        = string
  default     = ""
}

variable "enable_cost_management" {
  description = "Enable Cost Management exports"
  type        = bool
  default     = false
}

variable "enable_resource_graph" {
  description = "Enable Resource Graph queries"
  type        = bool
  default     = false
}

variable "enable_advisor" {
  description = "Enable Azure Advisor"
  type        = bool
  default     = false
}

variable "enable_governance_alerts" {
  description = "Enable governance monitoring alerts"
  type        = bool
  default     = false
}

variable "governance_alert_email" {
  description = "Email for governance alerts"
  type        = string
  default     = ""
}

variable "enable_governance_monitoring" {
  description = "Enable governance monitoring with Application Insights"
  type        = bool
  default     = false
}

variable "enable_custom_governance_roles" {
  description = "Enable custom governance roles"
  type        = bool
  default     = false
}

#================================================
# MIGRATION CONFIGURATION
#================================================

variable "enable_migrate_project" {
  description = "Enable Azure Migrate Project"
  type        = bool
  default     = false
}

variable "enable_database_migration_service" {
  description = "Enable Database Migration Service"
  type        = bool
  default     = false
}

variable "enable_migration_storage" {
  description = "Enable dedicated storage for migration"
  type        = bool
  default     = false
}

variable "enable_databox" {
  description = "Enable Azure Data Box for offline data transfer"
  type        = bool
  default     = false
}

variable "migration_contact_name" {
  description = "Contact name for migration services"
  type        = string
  default     = "Migration Admin"
}

variable "migration_contact_phone" {
  description = "Contact phone for migration services"
  type        = string
  default     = "+1-555-0123"
}

variable "migration_contact_email" {
  description = "Contact email for migration services"
  type        = string
  default     = "migration@trl.com"
}

variable "migration_shipping_address" {
  description = "Shipping address for Data Box"
  type        = string
  default     = "123 Main St"
}

variable "migration_shipping_city" {
  description = "Shipping city for Data Box"
  type        = string
  default     = "Anytown"
}

variable "migration_shipping_state" {
  description = "Shipping state for Data Box"
  type        = string
  default     = "CA"
}

variable "migration_shipping_country" {
  description = "Shipping country for Data Box"
  type        = string
  default     = "US"
}

variable "migration_shipping_postal_code" {
  description = "Shipping postal code for Data Box"
  type        = string
  default     = "12345"
}

variable "enable_site_recovery_migration" {
  description = "Enable Site Recovery for VM migration"
  type        = bool
  default     = false
}

variable "enable_migration_backup" {
  description = "Enable backup policies for migrated resources"
  type        = bool
  default     = false
}

variable "enable_app_migration" {
  description = "Enable App Service migration resources"
  type        = bool
  default     = false
}

variable "enable_import_export" {
  description = "Enable Azure Import/Export service"
  type        = bool
  default     = false
}

#================================================
# MIXED REALITY CONFIGURATION
#================================================

variable "enable_spatial_anchors" {
  description = "Enable Azure Spatial Anchors"
  type        = bool
  default     = false
}

variable "enable_remote_rendering" {
  description = "Enable Azure Remote Rendering"
  type        = bool
  default     = false
}

variable "enable_object_anchors" {
  description = "Enable Azure Object Anchors"
  type        = bool
  default     = false
}

variable "enable_mixed_reality_storage" {
  description = "Enable dedicated storage for Mixed Reality content"
  type        = bool
  default     = false
}

variable "enable_mixed_reality_cdn" {
  description = "Enable CDN for Mixed Reality content delivery"
  type        = bool
  default     = false
}

variable "enable_mixed_reality_media" {
  description = "Enable Media Services for Mixed Reality streaming"
  type        = bool
  default     = false
}

variable "enable_mixed_reality_acr" {
  description = "Enable Container Registry for Mixed Reality applications"
  type        = bool
  default     = false
}

#================================================
# MONITOR CONFIGURATION
#================================================

variable "enable_data_collection_endpoint" {
  description = "Enable Azure Monitor Data Collection Endpoint"
  type        = bool
  default     = false
}

variable "enable_data_collection_rule" {
  description = "Enable Azure Monitor Data Collection Rule"
  type        = bool
  default     = false
}

variable "enable_action_groups" {
  description = "Enable Azure Monitor Action Groups"
  type        = bool
  default     = false
}

variable "alert_email_address" {
  description = "Email address for alerts"
  type        = string
  default     = "alerts@trl.com"
}

variable "alert_sms_country_code" {
  description = "Country code for SMS alerts"
  type        = string
  default     = "1"
}

variable "alert_sms_phone_number" {
  description = "Phone number for SMS alerts"
  type        = string
  default     = "5550123"
}

variable "teams_webhook_url" {
  description = "Microsoft Teams webhook URL for alerts"
  type        = string
  default     = ""
}

variable "enable_metric_alerts" {
  description = "Enable Azure Monitor Metric Alerts"
  type        = bool
  default     = false
}

variable "enable_log_alerts" {
  description = "Enable Azure Monitor Log Alerts"
  type        = bool
  default     = false
}

variable "enable_workbooks" {
  description = "Enable Azure Monitor Workbooks"
  type        = bool
  default     = false
}

variable "enable_monitor_private_link" {
  description = "Enable Azure Monitor Private Link"
  type        = bool
  default     = false
}

#================================================
# WEB & MOBILE CONFIGURATION
#================================================

variable "enable_app_service" {
  description = "Enable Azure App Service"
  type        = bool
  default     = false
}

variable "app_service_sku" {
  description = "SKU for App Service Plan"
  type        = string
  default     = "B1"
}

variable "enable_app_service_environment" {
  description = "Enable App Service Environment"
  type        = bool
  default     = false
}

variable "enable_function_app" {
  description = "Enable Azure Function App"
  type        = bool
  default     = false
}

variable "enable_container_apps" {
  description = "Enable Azure Container Apps"
  type        = bool
  default     = false
}

variable "enable_spring_apps" {
  description = "Enable Azure Spring Apps"
  type        = bool
  default     = false
}

variable "spring_apps_sku" {
  description = "SKU for Azure Spring Apps"
  type        = string
  default     = "S0"
}

variable "enable_static_web_app" {
  description = "Enable Azure Static Web Apps"
  type        = bool
  default     = false
}

variable "static_web_app_sku" {
  description = "SKU for Static Web App"
  type        = string
  default     = "Free"
}

variable "enable_web_cdn" {
  description = "Enable CDN for web content"
  type        = bool
  default     = false
}

variable "enable_front_door" {
  description = "Enable Azure Front Door"
  type        = bool
  default     = false
}

variable "front_door_sku" {
  description = "SKU for Azure Front Door"
  type        = string
  default     = "Standard_AzureFrontDoor"
}

# API Management Configuration
variable "enable_api_management" {
  description = "Enable API Management"
  type        = bool
  default     = false
}

variable "api_management_publisher_name" {
  description = "Publisher name for API Management"
  type        = string
  default     = "TRL Organization"
}

variable "api_management_publisher_email" {
  description = "Publisher email for API Management"
  type        = string
  default     = "admin@trl.com"
}

variable "api_management_sku" {
  description = "SKU for API Management"
  type        = string
  default     = "Developer_1"
}

# App Configuration
variable "enable_app_configuration" {
  description = "Enable App Configuration"
  type        = bool
  default     = false
}

variable "app_configuration_sku" {
  description = "SKU for App Configuration"
  type        = string
  default     = "standard"
}

# Messaging and Notifications
variable "enable_communication_services" {
  description = "Enable Azure Communication Services"
  type        = bool
  default     = false
}

variable "enable_email_communication_services" {
  description = "Enable Email Communication Services"
  type        = bool
  default     = false
}

variable "enable_notification_hub" {
  description = "Enable Notification Hub"
  type        = bool
  default     = false
}

variable "enable_signalr" {
  description = "Enable Azure SignalR Service"
  type        = bool
  default     = false
}

variable "signalr_sku_name" {
  description = "SKU name for SignalR Service"
  type        = string
  default     = "Free_F1"
}

variable "signalr_capacity" {
  description = "Capacity for SignalR Service"
  type        = number
  default     = 1
}

variable "enable_web_pubsub" {
  description = "Enable Web PubSub Service"
  type        = bool
  default     = false
}

variable "web_pubsub_sku" {
  description = "SKU for Web PubSub Service"
  type        = string
  default     = "Free_F1"
}

variable "web_pubsub_capacity" {
  description = "Capacity for Web PubSub Service"
  type        = number
  default     = 1
}

variable "enable_fluid_relay" {
  description = "Enable Fluid Relay"
  type        = bool
  default     = false
}

# Media Services and Search
variable "enable_search_service" {
  description = "Enable Azure AI Search Service"
  type        = bool
  default     = false
}

variable "search_service_sku" {
  description = "SKU for Search Service"
  type        = string
  default     = "basic"
}

variable "search_service_replica_count" {
  description = "Number of replicas for Search Service"
  type        = number
  default     = 1
}

variable "search_service_partition_count" {
  description = "Number of partitions for Search Service"
  type        = number
  default     = 1
}

variable "enable_media_services" {
  description = "Enable Azure Media Services"
  type        = bool
  default     = false
}

variable "enable_mobile_backend" {
  description = "Enable mobile backend services"
  type        = bool
  default     = false
}

# Application Insights
variable "enable_app_insights" {
  description = "Enable Application Insights for apps"
  type        = bool
  default     = false
}
