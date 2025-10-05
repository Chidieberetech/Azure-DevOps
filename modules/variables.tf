# Variables for TRL Hub and Spoke Infrastructure

#================================================
# ENVIRONMENT CONFIGURATION
#================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

#================================================
# HUB AND SPOKE CONFIGURATION
#================================================

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
