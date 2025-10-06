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

# Private endpoints
variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
  default     = true
}

# Key Vault
variable "enable_key_vault" {
  description = "Enable Azure Key Vault"
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

# Log Analytics configuration
variable "log_analytics_sku" {
  description = "Log Analytics workspace SKU"
  type        = string
  default     = "PerGB2018"
  validation {
    condition = contains(["Free", "PerNode", "PerGB2018", "Premium"], var.log_analytics_sku)
    error_message = "Log Analytics SKU must be Free, PerNode, PerGB2018, or Premium."
  }
}

variable "log_analytics_daily_quota_gb" {
  description = "Daily data ingestion quota in GB for Log Analytics workspace"
  type        = number
  default     = -1 # -1 means no limit
}

# Application Insights configuration
variable "app_insights_retention_days" {
  description = "Application Insights data retention in days"
  type        = number
  default     = 90
  validation {
    condition = var.app_insights_retention_days >= 30 && var.app_insights_retention_days <= 730
    error_message = "Application Insights retention must be between 30 and 730 days."
  }
}

variable "app_insights_sampling_percentage" {
  description = "Application Insights sampling percentage"
  type        = number
  default     = 100
  validation {
    condition = var.app_insights_sampling_percentage >= 0 && var.app_insights_sampling_percentage <= 100
    error_message = "Sampling percentage must be between 0 and 100."
  }
}

# VM monitoring
variable "enable_vm_monitoring" {
  description = "Enable VM Insights monitoring"
  type        = bool
  default     = true
}

# Alert configuration
variable "alert_email_addresses" {
  description = "List of email addresses for alert notifications"
  type        = list(string)
  default     = []
}

variable "alert_sms_numbers" {
  description = "Map of SMS numbers for alert notifications"
  type = map(object({
    country_code = string
    phone_number = string
  }))
  default = {}
}

variable "alert_webhooks" {
  description = "Map of webhook URLs for alert notifications"
  type        = map(string)
  default     = {}
}

# Infrastructure alert thresholds
variable "enable_infrastructure_alerts" {
  description = "Enable infrastructure metric alerts"
  type        = bool
  default     = true
}

variable "cpu_alert_threshold" {
  description = "CPU usage percentage threshold for alerts"
  type        = number
  default     = 80
  validation {
    condition = var.cpu_alert_threshold >= 1 && var.cpu_alert_threshold <= 100
    error_message = "CPU alert threshold must be between 1 and 100."
  }
}

variable "memory_alert_threshold_bytes" {
  description = "Available memory threshold in bytes for alerts"
  type        = number
  default     = 1073741824 # 1GB
}

# Application alert thresholds
variable "enable_application_alerts" {
  description = "Enable application performance alerts"
  type        = bool
  default     = true
}

variable "response_time_alert_threshold_seconds" {
  description = "Application response time threshold in seconds for alerts"
  type        = number
  default     = 5
}

variable "error_rate_alert_threshold" {
  description = "Application error rate threshold for alerts"
  type        = number
  default     = 10
}

# Database alert thresholds
variable "enable_database_alerts" {
  description = "Enable database performance alerts"
  type        = bool
  default     = true
}

variable "database_cpu_alert_threshold" {
  description = "Database CPU usage percentage threshold for alerts"
  type        = number
  default     = 80
}

variable "database_storage_alert_threshold" {
  description = "Database storage usage percentage threshold for alerts"
  type        = number
  default     = 85
}

# Security alerts
variable "enable_security_alerts" {
  description = "Enable security-related alerts"
  type        = bool
  default     = true
}

# Dashboard and workbook configuration
variable "enable_monitoring_dashboard" {
  description = "Enable custom monitoring dashboard"
  type        = bool
  default     = true
}

variable "enable_monitoring_workbooks" {
  description = "Enable monitoring workbooks"
  type        = bool
  default     = true
}

#================================================
# ANALYTICS CONFIGURATION
#================================================

variable "enable_analytics" {
  description = "Enable analytics services"
  type        = bool
  default     = false
}

# Log Analytics Workspace
variable "log_analytics_retention_days" {
  description = "Log Analytics workspace data retention in days"
  type        = number
  default     = 30
  validation {
    condition = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Log Analytics retention must be between 30 and 730 days."
  }
}

# Application Insights
variable "enable_application_insights" {
  description = "Enable Application Insights"
  type        = bool
  default     = true
}

variable "application_insights_type" {
  description = "Application Insights application type"
  type        = string
  default     = "web"
  validation {
    condition = contains(["web", "java", "MobileCenter", "other"], var.application_insights_type)
    error_message = "Application Insights type must be web, java, MobileCenter, or other."
  }
}

# Data Factory
variable "enable_data_factory" {
  description = "Enable Azure Data Factory"
  type        = bool
  default     = false
}

# Data Lake Storage
variable "enable_data_lake" {
  description = "Enable Data Lake Storage Gen2"
  type        = bool
  default     = false
}

variable "data_lake_replication_type" {
  description = "Data Lake storage replication type"
  type        = string
  default     = "LRS"
  validation {
    condition = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.data_lake_replication_type)
    error_message = "Data Lake replication type must be LRS, GRS, RAGRS, or ZRS."
  }
}

# Synapse Analytics
variable "enable_synapse" {
  description = "Enable Azure Synapse Analytics"
  type        = bool
  default     = false
}

variable "synapse_sql_admin_login" {
  description = "Synapse SQL administrator login"
  type        = string
  default     = "sqladmin"
}

variable "synapse_sql_admin_password" {
  description = "Synapse SQL administrator password"
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_synapse_sql_pool" {
  description = "Enable Synapse SQL Pool"
  type        = bool
  default     = false
}

variable "synapse_sql_pool_sku" {
  description = "Synapse SQL Pool SKU"
  type        = string
  default     = "DW100c"
}

variable "enable_synapse_spark_pool" {
  description = "Enable Synapse Spark Pool"
  type        = bool
  default     = false
}

variable "synapse_spark_node_size" {
  description = "Synapse Spark Pool node size"
  type        = string
  default     = "Small"
  validation {
    condition = contains(["Small", "Medium", "Large"], var.synapse_spark_node_size)
    error_message = "Synapse Spark node size must be Small, Medium, or Large."
  }
}

variable "synapse_spark_node_count" {
  description = "Synapse Spark Pool node count"
  type        = number
  default     = 3
  validation {
    condition = var.synapse_spark_node_count >= 3 && var.synapse_spark_node_count <= 200
    error_message = "Synapse Spark node count must be between 3 and 200."
  }
}

variable "synapse_spark_min_nodes" {
  description = "Synapse Spark Pool minimum nodes for auto-scaling"
  type        = number
  default     = 3
}

variable "synapse_spark_max_nodes" {
  description = "Synapse Spark Pool maximum nodes for auto-scaling"
  type        = number
  default     = 10
}

variable "synapse_spark_auto_pause_delay" {
  description = "Synapse Spark Pool auto-pause delay in minutes"
  type        = number
  default     = 15
}

#================================================
# CONTAINER CONFIGURATION
#================================================

variable "enable_containers" {
  description = "Enable container services"
  type        = bool
  default     = false
}

# Azure Container Registry
variable "enable_container_registry" {
  description = "Enable Azure Container Registry"
  type        = bool
  default     = true
}

variable "container_registry_sku" {
  description = "Container Registry SKU"
  type        = string
  default     = "Basic"
  validation {
    condition = contains(["Basic", "Standard", "Premium"], var.container_registry_sku)
    error_message = "Container Registry SKU must be Basic, Standard, or Premium."
  }
}

variable "container_registry_admin_enabled" {
  description = "Enable Container Registry admin user"
  type        = bool
  default     = false
}

variable "enable_container_registry_georeplication" {
  description = "Enable Container Registry geo-replication (Premium SKU only)"
  type        = bool
  default     = false
}

# Azure Kubernetes Service (AKS)
variable "enable_aks" {
  description = "Enable Azure Kubernetes Service"
  type        = bool
  default     = false
}

variable "aks_kubernetes_version" {
  description = "AKS Kubernetes version"
  type        = string
  default     = null # Uses latest available version
}

variable "aks_node_count" {
  description = "AKS default node pool node count"
  type        = number
  default     = 2
  validation {
    condition = var.aks_node_count >= 1 && var.aks_node_count <= 100
    error_message = "AKS node count must be between 1 and 100."
  }
}

variable "aks_vm_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_B2s"
  validation {
    condition = contains([
      "Standard_B2s",
      "Standard_D2s_v3",
      "Standard_D2s_v4",
      "Standard_DS2_v2"
    ], var.aks_vm_size)
    error_message = "AKS VM size must be from the approved list."
  }
}

variable "aks_availability_zones" {
  description = "AKS availability zones"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "aks_enable_auto_scaling" {
  description = "Enable AKS auto-scaling"
  type        = bool
  default     = true
}

variable "aks_min_count" {
  description = "AKS minimum node count for auto-scaling"
  type        = number
  default     = 1
}

variable "aks_max_count" {
  description = "AKS maximum node count for auto-scaling"
  type        = number
  default     = 10
}

variable "aks_max_pods" {
  description = "Maximum pods per AKS node"
  type        = number
  default     = 30
}

variable "aks_os_disk_size" {
  description = "AKS node OS disk size in GB"
  type        = number
  default     = 128
}

variable "enable_aks_vnet_integration" {
  description = "Enable AKS VNet integration"
  type        = bool
  default     = true
}

variable "aks_subnet_address_prefix" {
  description = "AKS subnet address prefix"
  type        = string
  default     = "10.0.10.0/24"
}

variable "aks_dns_service_ip" {
  description = "AKS DNS service IP"
  type        = string
  default     = "10.0.11.10"
}

variable "aks_service_cidr" {
  description = "AKS service CIDR"
  type        = string
  default     = "10.0.11.0/24"
}

variable "enable_aks_rbac" {
  description = "Enable AKS Azure AD RBAC"
  type        = bool
  default     = true
}

variable "aks_admin_group_object_ids" {
  description = "Azure AD group object IDs for AKS admin access"
  type        = list(string)
  default     = []
}

variable "enable_aks_monitoring" {
  description = "Enable AKS monitoring with Log Analytics"
  type        = bool
  default     = true
}

variable "enable_aks_azure_policy" {
  description = "Enable AKS Azure Policy add-on"
  type        = bool
  default     = true
}

variable "enable_aks_http_application_routing" {
  description = "Enable AKS HTTP Application Routing add-on"
  type        = bool
  default     = false
}

# AKS Spot Node Pool
variable "enable_aks_spot_node_pool" {
  description = "Enable AKS spot node pool for cost optimization"
  type        = bool
  default     = false
}

variable "aks_spot_vm_size" {
  description = "AKS spot node pool VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "aks_spot_node_count" {
  description = "AKS spot node pool node count"
  type        = number
  default     = 1
}

variable "aks_spot_max_price" {
  description = "AKS spot node pool maximum price per hour"
  type        = number
  default     = -1 # -1 means pay up to on-demand price
}

# Container Instances
variable "enable_container_instances" {
  description = "Enable Azure Container Instances"
  type        = bool
  default     = false
}

variable "container_instances_ip_address_type" {
  description = "Container Instances IP address type"
  type        = string
  default     = "Public"
  validation {
    condition = contains(["Public", "Private"], var.container_instances_ip_address_type)
    error_message = "Container Instances IP address type must be Public or Private."
  }
}

variable "container_instances_dns_name_label" {
  description = "Container Instances DNS name label"
  type        = string
  default     = null
}

variable "enable_container_instances_vnet_integration" {
  description = "Enable Container Instances VNet integration"
  type        = bool
  default     = false
}

variable "containers_subnet_address_prefix" {
  description = "Container Instances subnet address prefix"
  type        = string
  default     = "10.0.12.0/24"
}

# Container Apps
variable "enable_container_apps" {
  description = "Enable Azure Container Apps"
  type        = bool
  default     = false
}

#================================================
# BACKUP CONFIGURATION
#================================================

variable "enable_backup" {
  description = "Enable Azure Backup services"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backup data"
  type        = number
  default     = 30
  validation {
    condition = var.backup_retention_days >= 7 && var.backup_retention_days <= 9999
    error_message = "Backup retention must be between 7 and 9999 days."
  }
}

#================================================
# SECURITY CENTER CONFIGURATION
#================================================

variable "enable_security_center" {
  description = "Enable Azure Security Center"
  type        = bool
  default     = true
}

variable "security_contact_email" {
  description = "Email address for security contact notifications"
  type        = string
  default     = ""
}

variable "enable_app_service" {
  description = "Enable App Service deployment"
  type        = bool
  default     = false
}

#================================================
# MONITORING CONFIGURATION
#================================================

variable "enable_security_monitoring" {
  description = "Enable security monitoring features"
  type        = bool
  default     = true
}

variable "enable_update_management" {
  description = "Enable Update Management solution"
  type        = bool
  default     = true
}

variable "enable_change_tracking" {
  description = "Enable Change Tracking and Inventory solution"
  type        = bool
  default     = true
}

variable "enable_cost_monitoring" {
  description = "Enable cost monitoring and budgets"
  type        = bool
  default     = true
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount for cost alerts"
  type        = number
  default     = 1000
  validation {
    condition = var.monthly_budget_amount > 0
    error_message = "Monthly budget amount must be greater than 0."
  }
}

variable "budget_alert_emails" {
  description = "List of email addresses for budget alerts"
  type        = list(string)
  default     = []
}

#================================================
# ADDITIONAL TAGS CONFIGURATION
#================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#================================================
# WEB & MOBILE SERVICES CONFIGURATION
#================================================

variable "app_service_sku" {
  description = "App Service plan SKU"
  type        = string
  default     = "B1"
  validation {
    condition = contains(["F1", "D1", "B1", "B2", "B3", "S1", "S2", "S3", "P1", "P2", "P3"], var.app_service_sku)
    error_message = "App Service SKU must be a valid tier."
  }
}

variable "enable_app_service_environment" {
  description = "Enable App Service Environment"
  type        = bool
  default     = false
}

variable "enable_app_insights" {
  description = "Enable Application Insights for apps"
  type        = bool
  default     = true
}

variable "enable_function_app" {
  description = "Enable Azure Functions"
  type        = bool
  default     = false
}

variable "enable_spring_apps" {
  description = "Enable Azure Spring Apps"
  type        = bool
  default     = false
}

variable "spring_apps_sku" {
  description = "Azure Spring Apps SKU"
  type        = string
  default     = "B0"
  validation {
    condition = contains(["B0", "S0"], var.spring_apps_sku)
    error_message = "Spring Apps SKU must be B0 or S0."
  }
}

variable "enable_static_web_app" {
  description = "Enable Azure Static Web Apps"
  type        = bool
  default     = false
}

variable "static_web_app_sku" {
  description = "Static Web App SKU"
  type        = string
  default     = "Free"
  validation {
    condition = contains(["Free", "Standard"], var.static_web_app_sku)
    error_message = "Static Web App SKU must be Free or Standard."
  }
}

variable "enable_api_management" {
  description = "Enable API Management"
  type        = bool
  default     = false
}

variable "api_management_publisher_name" {
  description = "API Management publisher name"
  type        = string
  default     = "TRL Organization"
}

variable "api_management_publisher_email" {
  description = "API Management publisher email"
  type        = string
  default     = "admin@example.com"
}

variable "api_management_sku" {
  description = "API Management SKU"
  type        = string
  default     = "Developer"
  validation {
    condition = contains(["Developer", "Basic", "Standard", "Premium"], var.api_management_sku)
    error_message = "API Management SKU must be Developer, Basic, Standard, or Premium."
  }
}

variable "enable_app_configuration" {
  description = "Enable App Configuration"
  type        = bool
  default     = false
}

variable "app_configuration_sku" {
  description = "App Configuration SKU"
  type        = string
  default     = "free"
  validation {
    condition = contains(["free", "standard"], var.app_configuration_sku)
    error_message = "App Configuration SKU must be free or standard."
  }
}

variable "enable_logic_apps" {
  description = "Enable Logic Apps"
  type        = bool
  default     = false
}

variable "enable_communication_services" {
  description = "Enable Communication Services"
  type        = bool
  default     = false
}

variable "enable_email_communication_services" {
  description = "Enable Email Communication Services"
  type        = bool
  default     = false
}

variable "enable_notification_hub" {
  description = "Enable Notification Hubs"
  type        = bool
  default     = false
}

variable "enable_signalr" {
  description = "Enable SignalR Service"
  type        = bool
  default     = false
}

variable "signalr_sku_name" {
  description = "SignalR Service SKU name"
  type        = string
  default     = "Free_F1"
  validation {
    condition = contains(["Free_F1", "Standard_S1"], var.signalr_sku_name)
    error_message = "SignalR SKU must be Free_F1 or Standard_S1."
  }
}

variable "signalr_capacity" {
  description = "SignalR Service capacity"
  type        = number
  default     = 1
  validation {
    condition = var.signalr_capacity >= 1 && var.signalr_capacity <= 100
    error_message = "SignalR capacity must be between 1 and 100."
  }
}

variable "enable_web_pubsub" {
  description = "Enable Web PubSub Service"
  type        = bool
  default     = false
}

variable "web_pubsub_sku" {
  description = "Web PubSub SKU"
  type        = string
  default     = "Free_F1"
  validation {
    condition = contains(["Free_F1", "Standard_S1"], var.web_pubsub_sku)
    error_message = "Web PubSub SKU must be Free_F1 or Standard_S1."
  }
}

variable "web_pubsub_capacity" {
  description = "Web PubSub capacity"
  type        = number
  default     = 1
  validation {
    condition = var.web_pubsub_capacity >= 1 && var.web_pubsub_capacity <= 100
    error_message = "Web PubSub capacity must be between 1 and 100."
  }
}

variable "enable_fluid_relay" {
  description = "Enable Azure Fluid Relay"
  type        = bool
  default     = false
}

variable "enable_search_service" {
  description = "Enable Azure Cognitive Search"
  type        = bool
  default     = false
}

variable "search_service_sku" {
  description = "Azure Cognitive Search SKU"
  type        = string
  default     = "free"
  validation {
    condition = contains(["free", "basic", "standard", "standard2", "standard3"], var.search_service_sku)
    error_message = "Search service SKU must be free, basic, standard, standard2, or standard3."
  }
}

variable "search_service_replica_count" {
  description = "Search service replica count"
  type        = number
  default     = 1
  validation {
    condition = var.search_service_replica_count >= 1 && var.search_service_replica_count <= 12
    error_message = "Search service replica count must be between 1 and 12."
  }
}

variable "search_service_partition_count" {
  description = "Search service partition count"
  type        = number
  default     = 1
  validation {
    condition = var.search_service_partition_count >= 1 && var.search_service_partition_count <= 12
    error_message = "Search service partition count must be between 1 and 12."
  }
}

variable "enable_media_services" {
  description = "Enable Azure Media Services"
  type        = bool
  default     = false
}

variable "enable_web_cdn" {
  description = "Enable Azure CDN"
  type        = bool
  default     = false
}

variable "enable_front_door" {
  description = "Enable Azure Front Door"
  type        = bool
  default     = false
}

variable "front_door_sku" {
  description = "Azure Front Door SKU"
  type        = string
  default     = "Standard_AzureFrontDoor"
  validation {
    condition = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.front_door_sku)
    error_message = "Front Door SKU must be Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "enable_mobile_backend" {
  description = "Enable mobile backend services"
  type        = bool
  default     = false
}

#================================================
# IOT SERVICES CONFIGURATION
#================================================

variable "enable_iot_hub" {
  description = "Enable IoT Hub"
  type        = bool
  default     = false
}

variable "iot_hub_sku_name" {
  description = "IoT Hub SKU name"
  type        = string
  default     = "F1"
  validation {
    condition = contains(["F1", "S1", "S2", "S3"], var.iot_hub_sku_name)
    error_message = "IoT Hub SKU must be F1, S1, S2, or S3."
  }
}

variable "iot_hub_capacity" {
  description = "IoT Hub capacity"
  type        = number
  default     = 1
  validation {
    condition = var.iot_hub_capacity >= 1 && var.iot_hub_capacity <= 200
    error_message = "IoT Hub capacity must be between 1 and 200."
  }
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
  description = "Azure Maps SKU name"
  type        = string
  default     = "S0"
  validation {
    condition = contains(["S0", "S1"], var.maps_sku_name)
    error_message = "Maps SKU must be S0 or S1."
  }
}

#================================================
# INTEGRATION SERVICES CONFIGURATION
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
  description = "Application Gateway SKU name"
  type        = string
  default     = "Standard_v2"
  validation {
    condition = contains(["Standard_v2", "WAF_v2"], var.app_gateway_sku_name)
    error_message = "Application Gateway SKU must be Standard_v2 or WAF_v2."
  }
}

variable "app_gateway_sku_tier" {
  description = "Application Gateway SKU tier"
  type        = string
  default     = "Standard_v2"
  validation {
    condition = contains(["Standard_v2", "WAF_v2"], var.app_gateway_sku_tier)
    error_message = "Application Gateway SKU tier must be Standard_v2 or WAF_v2."
  }
}

variable "app_gateway_capacity" {
  description = "Application Gateway capacity"
  type        = number
  default     = 2
  validation {
    condition = var.app_gateway_capacity >= 1 && var.app_gateway_capacity <= 125
    error_message = "Application Gateway capacity must be between 1 and 125."
  }
}

variable "enable_relay" {
  description = "Enable Azure Relay"
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

variable "enable_mixed_reality_storage" {
  description = "Enable storage for mixed reality assets"
  type        = bool
  default     = false
}

variable "enable_mixed_reality_cdn" {
  description = "Enable CDN for mixed reality content"
  type        = bool
  default     = false
}

variable "enable_mixed_reality_acr" {
  description = "Enable Container Registry for mixed reality applications"
  type        = bool
  default     = false
}

#================================================
# MIGRATION SERVICES CONFIGURATION
#================================================

variable "enable_migration_storage" {
  description = "Enable storage for migration purposes"
  type        = bool
  default     = false
}

variable "enable_database_migration_service" {
  description = "Enable Azure Database Migration Service"
  type        = bool
  default     = false
}

variable "enable_site_recovery_migration" {
  description = "Enable Azure Site Recovery for migration"
  type        = bool
  default     = false
}

variable "enable_migration_backup" {
  description = "Enable backup services for migration"
  type        = bool
  default     = false
}

variable "enable_app_migration" {
  description = "Enable app migration services"
  type        = bool
  default     = false
}

variable "enable_import_export" {
  description = "Enable Azure Import/Export service"
  type        = bool
  default     = false
}

#================================================
# MANAGEMENT & GOVERNANCE CONFIGURATION
#================================================

variable "enable_policy" {
  description = "Enable Azure Policy"
  type        = bool
  default     = true
}

variable "enable_management_group" {
  description = "Enable Management Groups"
  type        = bool
  default     = false
}

variable "enable_cost_management" {
  description = "Enable Cost Management and Billing"
  type        = bool
  default     = true
}

variable "enable_governance_alerts" {
  description = "Enable governance-related alerts"
  type        = bool
  default     = true
}

variable "governance_alert_email" {
  description = "Email address for governance alerts"
  type        = string
  default     = ""
}

variable "enable_governance_monitoring" {
  description = "Enable governance monitoring"
  type        = bool
  default     = true
}

variable "enable_custom_governance_roles" {
  description = "Enable custom governance roles"
  type        = bool
  default     = false
}

#================================================
# IDENTITY SERVICES CONFIGURATION
#================================================

variable "enable_aad_ds" {
  description = "Enable Azure Active Directory Domain Services"
  type        = bool
  default     = false
}

variable "aad_ds_domain_name" {
  description = "Domain name for Azure AD Domain Services"
  type        = string
  default     = "trl.local"
  validation {
    condition = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\\.[a-zA-Z]{2,}$", var.aad_ds_domain_name))
    error_message = "Domain name must be a valid FQDN format."
  }
}

variable "enable_managed_identity" {
  description = "Enable User Assigned Managed Identity"
  type        = bool
  default     = true
}

variable "enable_aad_b2c" {
  description = "Enable Azure Active Directory B2C"
  type        = bool
  default     = false
}

variable "aad_b2c_country_code" {
  description = "Country code for Azure AD B2C tenant"
  type        = string
  default     = "US"
  validation {
    condition = contains(["US", "EU", "GB", "CA", "AU"], var.aad_b2c_country_code)
    error_message = "B2C country code must be US, EU, GB, CA, or AU."
  }
}

variable "enable_identity_keyvault" {
  description = "Enable dedicated Key Vault for identity services"
  type        = bool
  default     = false
}

variable "enable_custom_roles" {
  description = "Enable custom RBAC roles"
  type        = bool
  default     = false
}

#================================================
# AI & MACHINE LEARNING CONFIGURATION
#================================================

variable "enable_cognitive_services" {
  description = "Enable Azure Cognitive Services"
  type        = bool
  default     = false
}

variable "cognitive_services_sku" {
  description = "Cognitive Services SKU"
  type        = string
  default     = "S0"
  validation {
    condition = contains(["F0", "S0", "S1", "S2", "S3", "S4"], var.cognitive_services_sku)
    error_message = "Cognitive Services SKU must be F0, S0, S1, S2, S3, or S4."
  }
}

variable "enable_machine_learning" {
  description = "Enable Azure Machine Learning"
  type        = bool
  default     = false
}

#================================================
# DEVOPS CONFIGURATION
#================================================

variable "enable_devops" {
  description = "Enable DevOps services and tools"
  type        = bool
  default     = false
}

#================================================
# GENERAL SERVICES CONFIGURATION
#================================================

variable "enable_automation" {
  description = "Enable Azure Automation"
  type        = bool
  default     = false
}

variable "enable_service_bus" {
  description = "Enable Azure Service Bus"
  type        = bool
  default     = false
}
