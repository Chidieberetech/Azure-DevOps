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

