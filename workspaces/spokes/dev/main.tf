# Dev Environment Configuration
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
      purge_soft_delete_on_destroy    = true
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

# Spoke infrastructure for dev environment
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

  # Tags for resources
  additional_tags = {
    Workspace                 = "Spoke-Dev"
    Environment               = var.environment
    Purpose                   = "Development Workloads"
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
    CostOptimized             = "true"
  }
}


