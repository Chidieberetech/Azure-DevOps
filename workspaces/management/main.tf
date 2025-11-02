# Management Workspace Configuration

# The Management Workspace is a dedicated environment for centralized monitoring, governance, and operational management of your Azure infrastructure. Unlike the Hub workspace (which manages networking and shared services) or Spoke workspaces (which host workloads), the Management workspace focuses on:
# Monitoring & Logging: Centralized Log Analytics, Application Insights
# Governance: Azure Policy, Blueprints, Cost Management
# Security & Compliance: Security Center, Sentinel (if enabled)
# Operational Tools: Automation accounts, backup management

# It has NO network components (firewall, bastion, VNets) as those are managed by the Hub workspace.

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

# Management infrastructure (monitoring, governance, etc.)
module "management_infrastructure" {
  source = "../../modules"

  # Environment configuration
  environment     = var.environment
  location        = var.location
  subscription_id = var.subscription_id

  # Disable network components (managed by hub workspace)
  enable_firewall    = var.enable_firewall
  enable_bastion     = var.enable_bastion
  enable_private_dns = var.enable_private_dns

  # Only deploy management components
  spoke_count = var.spoke_count

  # VM configuration (required by module even if VMs not deployed)
  vm_size                 = var.vm_size
  admin_username          = var.admin_username
  admin_password          = var.admin_password
  enable_vm_auto_shutdown = var.enable_vm_auto_shutdown
  vm_shutdown_time        = var.vm_shutdown_time
  enable_vm_monitoring    = var.enable_vm_monitoring

  # Monitoring & Governance configuration
  enable_monitoring            = var.enable_monitoring
  log_retention_days           = var.log_retention_days
  log_analytics_sku            = var.log_analytics_sku
  log_analytics_daily_quota_gb = var.log_analytics_daily_quota_gb
  app_insights_retention_days  = var.app_insights_retention_days
  enable_monitoring_dashboard  = var.enable_monitoring_dashboard

  # Alerting configuration
  enable_infrastructure_alerts = var.enable_infrastructure_alerts
  alert_email_addresses        = var.alert_email_addresses
  enable_security_alerts       = var.enable_security_alerts

  # Security configuration
  enable_key_vault             = var.enable_key_vault
  enable_key_vault_soft_delete = var.enable_key_vault_soft_delete

  # Storage configuration
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_replication_type

  # Tags for resources
  additional_tags = {
    Workspace                 = "Management"
    Purpose                   = "Monitoring and Governance"
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
    WorkspaceType             = "Management"
  }
}
