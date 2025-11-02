# Management Workspace Variables

#================================================
# BACKEND CONFIGURATION
#================================================

variable "backendResourceGroupName" {
  description = "Resource group name for backend storage"
  type        = string
}

variable "backendStorageAccountName" {
  description = "Storage account name for backend"
  type        = string
}

variable "backendContainerName" {
  description = "Container name for backend"
  type        = string
}

#================================================
# CORE CONFIGURATION
#================================================

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "environment" {
  description = "Environment name for the management workspace"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "int", "prod"], var.environment)
    error_message = "Environment must be dev, int, or prod."
  }
}

variable "location" {
  description = "Primary Azure region for management resources"
  type        = string
  default     = "West Europe"
}

#================================================
# NETWORK CONFIGURATION
# Network components are disabled in management workspace
# as they are managed by the hub workspace
#================================================

variable "enable_firewall" {
  description = "Enable Azure Firewall (always false for management workspace)"
  type        = bool
  default     = false
}

variable "enable_bastion" {
  description = "Enable Azure Bastion (always false for management workspace)"
  type        = bool
  default     = false
}

variable "enable_private_dns" {
  description = "Enable private DNS zones (always false for management workspace)"
  type        = bool
  default     = false
}

variable "spoke_count" {
  description = "Number of spoke networks (always 0 for management workspace)"
  type        = number
  default     = 0
}

#================================================
# COMPUTE CONFIGURATION
# VM configuration required by module even if VMs not deployed
#================================================

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureadmin"
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password for virtual machines"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_vm_auto_shutdown" {
  description = "Enable automatic VM shutdown"
  type        = bool
  default     = false
}

variable "vm_shutdown_time" {
  description = "Time to automatically shutdown VMs (24-hour format)"
  type        = string
  default     = "1900"
}

variable "enable_vm_monitoring" {
  description = "Enable VM Insights monitoring"
  type        = bool
  default     = false
}

#================================================
# MONITORING & GOVERNANCE CONFIGURATION
#================================================

variable "enable_monitoring" {
  description = "Enable Azure Monitor and Log Analytics"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 90
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

variable "log_analytics_sku" {
  description = "Log Analytics workspace SKU"
  type        = string
  default     = "PerGB2018"
  validation {
    condition     = contains(["Free", "PerNode", "PerGB2018", "Premium"], var.log_analytics_sku)
    error_message = "Log Analytics SKU must be Free, PerNode, PerGB2018, or Premium."
  }
}

variable "log_analytics_daily_quota_gb" {
  description = "Daily data ingestion quota in GB for Log Analytics workspace"
  type        = number
  default     = -1
}

variable "app_insights_retention_days" {
  description = "Application Insights data retention in days"
  type        = number
  default     = 90
  validation {
    condition     = var.app_insights_retention_days >= 30 && var.app_insights_retention_days <= 730
    error_message = "Application Insights retention must be between 30 and 730 days."
  }
}

variable "enable_monitoring_dashboard" {
  description = "Enable custom monitoring dashboard"
  type        = bool
  default     = true
}

#================================================
# ALERTING CONFIGURATION
#================================================

variable "enable_infrastructure_alerts" {
  description = "Enable infrastructure metric alerts"
  type        = bool
  default     = true
}

variable "alert_email_addresses" {
  description = "List of email addresses for alert notifications"
  type        = list(string)
  default     = ["infrastructure@trl.com"]
}

variable "enable_security_alerts" {
  description = "Enable security-related alerts"
  type        = bool
  default     = true
}

#================================================
# SECURITY CONFIGURATION
#================================================

variable "enable_key_vault" {
  description = "Enable Azure Key Vault for secrets management"
  type        = bool
  default     = true
}

variable "enable_key_vault_soft_delete" {
  description = "Enable Key Vault soft delete"
  type        = bool
  default     = true
}

#================================================
# STORAGE CONFIGURATION
#================================================

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be Standard or Premium."
  }
}

variable "storage_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "GRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage_replication_type)
    error_message = "Storage replication type must be LRS, GRS, RAGRS, or ZRS."
  }
}

#================================================
# COST MANAGEMENT
#================================================

variable "enable_cost_management_alerts" {
  description = "Enable cost management and budget alerts"
  type        = bool
  default     = true
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount for cost alerts (in USD)"
  type        = number
  default     = 5000
}

#================================================
# TAGGING
#================================================

variable "created_by" {
  description = "Name or identifier of the person/team who created the resources"
  type        = string
  default     = "TRL Infrastructure Team"
}

variable "service_provider" {
  description = "Service provider responsible for the resources"
  type        = string
  default     = "TRL Technology Services"
}

variable "cost_center" {
  description = "Cost center for billing and chargeback"
  type        = string
  default     = "IT-Infrastructure"
}

variable "business_unit" {
  description = "Business unit owning the resources"
  type        = string
  default     = "Technology"
}

variable "project_name" {
  description = "Project name for the infrastructure"
  type        = string
  default     = "Hub-Spoke-Architecture"
}

variable "owner_email" {
  description = "Email address of the resource owner"
  type        = string
  default     = "infrastructure@trl.com"
}

variable "data_classification" {
  description = "Data classification level"
  type        = string
  default     = "Internal"
  validation {
    condition     = contains(["Public", "Internal", "Confidential", "Restricted"], var.data_classification)
    error_message = "Data classification must be Public, Internal, Confidential, or Restricted."
  }
}

variable "compliance_requirements" {
  description = "Compliance frameworks applicable to resources"
  type        = list(string)
  default     = ["ISO-27001", "SOC2"]
}

variable "backup_required" {
  description = "Whether resources require backup"
  type        = bool
  default     = true
}

variable "disaster_recovery_tier" {
  description = "Disaster recovery tier (Tier1=Critical, Tier2=Important, Tier3=Standard)"
  type        = string
  default     = "Tier1"
  validation {
    condition     = contains(["Tier1", "Tier2", "Tier3"], var.disaster_recovery_tier)
    error_message = "DR tier must be Tier1, Tier2, or Tier3."
  }
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "Saturday 02:00-06:00 UTC"
}

variable "additional_tags" {
  description = "Additional custom tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy     = "Terraform"
    Repository    = "Azure.IAC.hubspoke"
    WorkspaceType = "Management"
  }
}

