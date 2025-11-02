# Hub Workspace Configuration
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

# Use the hub and spoke module
module "hub_infrastructure" {
  source = "../../modules"

  # Environment configuration
  environment     = var.environment
  location        = var.location
  subscription_id = var.subscription_id

  # Network configuration
  enable_firewall          = var.enable_firewall
  enable_bastion           = var.enable_bastion
  enable_private_dns       = var.enable_private_dns
  enable_ddos_protection   = var.enable_ddos_protection
  enable_private_endpoints = var.enable_private_endpoints

  # Deploy spokes with VMs
  spoke_count = var.spoke_count

  # Storage configuration
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_replication_type
  enable_premium_storage   = var.enable_premium_storage
  enable_data_lake_storage = var.enable_data_lake_storage

  # Database configuration
  enable_sql_database = var.enable_sql_database
  enable_cosmos_db    = var.enable_cosmos_db

  # VM configuration
  vm_size                 = var.vm_size
  admin_username          = var.admin_username
  admin_password          = var.admin_password
  enable_vm_auto_shutdown = var.enable_vm_auto_shutdown
  vm_shutdown_time        = var.vm_shutdown_time
  enable_vm_monitoring    = var.enable_vm_monitoring

  # Security configuration
  enable_key_vault             = var.enable_key_vault
  enable_key_vault_soft_delete = var.enable_key_vault_soft_delete

  # Monitoring configuration
  enable_monitoring            = var.enable_monitoring
  log_retention_days           = var.log_retention_days
  log_analytics_sku            = var.log_analytics_sku
  log_analytics_daily_quota_gb = var.log_analytics_daily_quota_gb
  app_insights_retention_days  = var.app_insights_retention_days
  enable_monitoring_dashboard  = var.enable_monitoring_dashboard

  # Alerting configuration
  enable_infrastructure_alerts = var.enable_infrastructure_alerts
  alert_email_addresses        = var.alert_email_addresses
  cpu_alert_threshold          = var.cpu_alert_threshold
  memory_alert_threshold_bytes = var.memory_alert_threshold_bytes
  enable_security_alerts       = var.enable_security_alerts

  # Tags for resources
  additional_tags = {
    Workspace                 = "Hub"
    Purpose                   = "Shared Services and Spokes"
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
  }
}
