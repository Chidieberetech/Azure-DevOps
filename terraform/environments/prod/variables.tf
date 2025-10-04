# Variables for Azure Hub and Spoke Infrastructure

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "HubAndSpoke"
    ManagedBy   = "Terraform"
  }
}

# Resource Group Names
variable "hub_resource_group_name" {
  description = "Name of the hub resource group"
  type        = string
  default     = "rg-hub-prod-we"
}

variable "spoke1_resource_group_name" {
  description = "Name of the spoke 1 resource group"
  type        = string
  default     = "rg-spoke1-prod-we"
}

variable "spoke2_resource_group_name" {
  description = "Name of the spoke 2 resource group"
  type        = string
  default     = "rg-spoke2-prod-we"
}

# Network Configuration
variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
  default     = "vnet-hub-prod-we"
}

variable "hub_address_space" {
  description = "Address space for hub VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "spoke1_vnet_name" {
  description = "Name of the spoke 1 virtual network"
  type        = string
  default     = "vnet-spoke1-prod-we"
}

variable "spoke1_address_space" {
  description = "Address space for spoke 1 VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "spoke2_vnet_name" {
  description = "Name of the spoke 2 virtual network"
  type        = string
  default     = "vnet-spoke2-prod-we"
}

variable "spoke2_address_space" {
  description = "Address space for spoke 2 VNet"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

# Security Configuration
variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
  default     = "kv-hubspoke-prod-we"
}

variable "firewall_name" {
  description = "Name of the Azure Firewall"
  type        = string
  default     = "afw-hub-prod-we"
}

variable "bastion_name" {
  description = "Name of the Azure Bastion"
  type        = string
  default     = "bas-hub-prod-we"
}

# Compute Configuration
variable "spoke1_vm_name" {
  description = "Name of the VM in spoke 1"
  type        = string
  default     = "vm-spoke1-prod-we"
}

variable "spoke2_vm_name" {
  description = "Name of the VM in spoke 2"
  type        = string
  default     = "vm-spoke2-prod-we"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureadmin"
}

variable "vm_size" {
  description = "Size of the virtual machines (Free tier compatible)"
  type        = string
  default     = "Standard_B1s"
}

# Storage Configuration
variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
  default     = "sthubspokeprodwe"
}

# Database Configuration
variable "sql_server_name" {
  description = "Name of the SQL Server"
  type        = string
  default     = "sql-hubspoke-prod-we"
}

variable "database_name" {
  description = "Name of the SQL Database"
  type        = string
  default     = "sqldb-main-prod"
}

variable "sql_admin_username" {
  description = "SQL Server admin username"
  type        = string
  default     = "sqladmin"
}
