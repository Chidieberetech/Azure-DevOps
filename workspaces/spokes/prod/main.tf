# Production Environment Configuration
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "trl-hubspoke-tfstate-rg"
    storage_account_name = "trlhubspoketfstate"
    container_name      = "tfstate"
    key                 = "prod.terraform.tfstate"
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
    resource_group_name  = "trl-hubspoke-tfstate-rg"
    storage_account_name = "trlhubspoketfstate"
    container_name      = "tfstate"
    key                 = "hub.terraform.tfstate"
  }
}

# Spoke infrastructure for production environment
module "spoke_infrastructure" {
  source = "../../../modules"

  # Environment configuration
  environment     = "prod"
  location        = "West Europe"
  subscription_id = var.subscription_id

  # Network configuration - spokes only
  enable_firewall    = false  # Hub manages firewall
  enable_bastion     = false  # Hub manages bastion
  enable_private_dns = false  # Hub manages DNS

  # Deploy 2 spokes for production
  spoke_count = 2

  # Compute configuration
  vm_size                   = "Standard_B2s"  # Larger size for prod
  enable_vm_auto_shutdown   = false           # No auto-shutdown in prod

  # Storage configuration
  storage_account_tier     = "Standard"
  storage_replication_type = "GRS"  # Geo-redundant for prod

  # Database configuration
  enable_sql_database = true
  sql_database_sku   = "S1"  # Higher tier for prod
  enable_cosmos_db   = true  # Enable Cosmos DB for prod

  # Enable monitoring
  enable_monitoring = true

  additional_tags = {
    Environment = "Production"
    Workspace   = "Spokes-Prod"
    Purpose     = "Production Workloads"
    CriticalityLevel = "High"
  }
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

