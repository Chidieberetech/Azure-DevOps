# Prod Spoke Workspace Variables

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
  default     = "prod"
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

variable "vm_vnet_address_space" {
  description = "Address space for the Windows VM VNet"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "vm_subnet_prefix" {
  description = "Subnet prefix for Windows VM"
  type        = list(string)
  default     = ["10.10.1.0/24"]
}

variable "sftp_vnet_address_space" {
  description = "Address space for the SFTP Storage VNet"
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "sftp_subnet_prefix" {
  description = "Subnet prefix for SFTP storage"
  type        = list(string)
  default     = ["10.20.1.0/24"]
}

#================================================
# COMPUTE CONFIGURATION
#================================================

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureadmin"
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}

variable "vm_admin_password" {
  description = "Admin password for VMs (alternative name)"
  type        = string
  sensitive   = true
}

variable "enable_vm_auto_shutdown" {
  description = "Enable automatic VM shutdown for cost optimization"
  type        = bool
  default     = false
}

variable "vm_shutdown_time" {
  description = "Time to automatically shutdown VMs (24-hour format)"
  type        = string
  default     = "2200"
}

variable "enable_vm_monitoring" {
  description = "Enable VM Insights monitoring"
  type        = bool
  default     = true
}

variable "enable_windows_vm" {
  description = "Enable Windows VM deployment"
  type        = bool
  default     = false
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

variable "enable_sftp_storage" {
  description = "Enable SFTP storage account deployment"
  type        = bool
  default     = false
}

variable "sftp_allowed_ip" {
  description = "Allowed IP address for SFTP storage account access"
  type        = string
  default     = ""
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
}

variable "enable_cosmos_db" {
  description = "Enable Cosmos DB deployment"
  type        = bool
  default     = false
}

variable "sql_admin_password" {
  description = "Admin password for SQL databases"
  type        = string
  sensitive   = true
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
  default     = 90
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 365
    error_message = "Log retention must be between 30 and 365 days."
  }
}

variable "admin_phone_number" {
  description = "Admin phone number for SMS alerts (optional, e.g., +1234567890)"
  type        = string
  default     = ""
  validation {
    condition     = var.admin_phone_number == "" || can(regex("^\\+?[1-9][0-9]{7,14}$", var.admin_phone_number))
    error_message = "Phone number must be in E.164 format (e.g., +1234567890) or empty. It should start with + followed by country code and 8-15 digits."
  }
}

#================================================
# TAGGING
#================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "company_name" {
  description = "Company name for tagging"
  type        = string
  default     = "TRL"
}

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
  default     = "Confidential"
  validation {
    condition     = contains(["Public", "Internal", "Confidential", "Restricted"], var.data_classification)
    error_message = "Data classification must be Public, Internal, Confidential, or Restricted."
  }
}

variable "compliance_requirements" {
  description = "Compliance frameworks applicable to resources"
  type        = list(string)
  default     = ["ISO-27001", "SOC2", "PCI-DSS"]
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


#================================================
# COMMON TAGS
#================================================

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

locals {
  # All common tags defined once
  all_common_tags = {
    Environment               = var.environment
    "Created By"              = var.created_by
    "Service Provider"        = var.service_provider
    "Cost Center"             = var.cost_center
    "Business Unit"           = var.business_unit
    "Project Name"            = var.project_name
    "Owner Email"             = var.owner_email
    "Data Classification"     = var.data_classification
    "Compliance Requirements" = join(", ", var.compliance_requirements)
    "Backup Required"         = var.backup_required ? "Yes" : "No"
    "Disaster Recovery Tier"  = var.disaster_recovery_tier
    "Maintenance Window"      = var.maintenance_window
    ManagedBy                 = "Terraform"
    Repository                = "Azure.IAC.hubspoke"
    CriticalityLevel          = "High"
  }

  # Merge with any additional common tags from variable
  base_tags = merge(local.all_common_tags, var.common_tags)

  # Specific tag sets
  sftp_tags = merge(local.base_tags, {
    Workspace = "Spoke-Prod-SFTP"
    Purpose   = "SFTP Storage Infrastructure"
  })

  windows_vm_tags = merge(local.base_tags, {
    Workspace = "Spoke-Prod-WinVM"
    Purpose   = "Windows VM Infrastructure"
  })

  spoke_tags = merge(local.base_tags, {
    Workspace = "Spoke-Prod"
    Purpose   = "Production Workloads"
  })
}

