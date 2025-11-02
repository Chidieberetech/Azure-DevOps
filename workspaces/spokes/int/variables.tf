# Int Spoke Workspace Variables

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

variable "hubBackendKey" {
  description = "State file key for hub workspace"
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
  description = "Environment name for the spoke workspace"
  type        = string
  default     = "int"
  validation {
    condition     = contains(["dev", "int", "prod"], var.environment)
    error_message = "Environment must be dev, int, or prod."
  }
}

variable "location" {
  description = "Primary Azure region for spoke resources"
  type        = string
  default     = "West Europe"
}

#================================================
# NETWORK CONFIGURATION
# Network components disabled - managed by hub
#================================================

variable "enable_firewall" {
  description = "Enable Azure Firewall (always false - managed by hub)"
  type        = bool
  default     = false
}

variable "enable_bastion" {
  description = "Enable Azure Bastion (always false - managed by hub)"
  type        = bool
  default     = false
}

variable "enable_private_dns" {
  description = "Enable private DNS zones (always false - managed by hub)"
  type        = bool
  default     = false
}

variable "spoke_count" {
  description = "Number of spoke networks to deploy"
  type        = number
  default     = 2
  validation {
    condition     = var.spoke_count >= 0 && var.spoke_count <= 3
    error_message = "Spoke count must be between 0 and 3."
  }
}

#================================================
# COMPUTE CONFIGURATION
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
  description = "Enable automatic VM shutdown for cost optimization"
  type        = bool
  default     = true
}

variable "vm_shutdown_time" {
  description = "Time to automatically shutdown VMs (24-hour format)"
  type        = string
  default     = "2000"
}

variable "enable_vm_monitoring" {
  description = "Enable VM Insights monitoring"
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
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage_replication_type)
    error_message = "Storage replication type must be LRS, GRS, RAGRS, or ZRS."
  }
}

#================================================
# DATABASE CONFIGURATION
#================================================

variable "enable_sql_database" {
  description = "Enable SQL Database deployment"
  type        = bool
  default     = true
}

variable "sql_database_sku" {
  description = "SQL Database SKU"
  type        = string
  default     = "S0"
  validation {
    condition     = contains(["Basic", "S0", "S1", "S2"], var.sql_database_sku)
    error_message = "SQL Database SKU must be Basic, S0, S1, or S2."
  }
}

variable "enable_cosmos_db" {
  description = "Enable Cosmos DB deployment"
  type        = bool
  default     = false
}

#================================================
# MONITORING CONFIGURATION
#================================================

variable "enable_monitoring" {
  description = "Enable Azure Monitor and Log Analytics"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 60
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 365
    error_message = "Log retention must be between 30 and 365 days."
  }
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
  default     = "Tier2"
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

