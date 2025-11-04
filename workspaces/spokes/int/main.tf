# Integration Environment Configuration
terraform {
  required_version = "1.13.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.51.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }

  backend "azurerm" {
    # Backend configuration provided via -backend-config during terraform init
  }
}


provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false  # Service principal lacks purge permission
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data sources for hub infrastructure
data "terraform_remote_state" "hub" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.backendResourceGroupName
    storage_account_name = var.backendStorageAccountName
    container_name       = var.backendContainerName
    key                  = var.hubBackendKey
  }
}

# Spoke infrastructure for integration environment
module "spoke_infrastructure" {
  source = "../../../modules"

  # Environment configuration
  environment     = var.environment
  location        = var.location
  subscription_id = var.subscription_id

  # Network configuration - spokes only
  enable_firewall    = var.enable_firewall
  enable_bastion     = var.enable_bastion
  enable_private_dns = var.enable_private_dns

  # Deploy spokes
  spoke_count = var.spoke_count

  # Compute configuration
  vm_size                 = var.vm_size
  admin_username          = var.admin_username
  admin_password          = var.admin_password
  enable_vm_auto_shutdown = var.enable_vm_auto_shutdown
  vm_shutdown_time        = var.vm_shutdown_time
  enable_vm_monitoring    = var.enable_vm_monitoring

  # Storage configuration
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_replication_type

  # Database configuration
  enable_sql_database = var.enable_sql_database
  sql_database_sku    = var.sql_database_sku
  enable_cosmos_db    = var.enable_cosmos_db

  # Monitoring configuration
  enable_monitoring  = var.enable_monitoring
  log_retention_days = var.log_retention_days

  # Tags for resources - Limited to 2 additional tags to stay within Azure's 15 tag limit
  # Base common_tags already include: Environment, CostCenter, BusinessUnit, Compliance, DataClassification, BackupRequired
  additional_tags = {
    Workspace = "Spoke-Int"
    Purpose   = "Integration-Testing"
  }
}


