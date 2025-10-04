# Staging Environment Configuration
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
    key                 = "staging.terraform.tfstate"
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

# Spoke infrastructure for staging environment
module "spoke_infrastructure" {
  source = "../../../modules"

  # Environment configuration
  environment     = "staging"
  location        = "West Europe"
  subscription_id = var.subscription_id

  # Network configuration - spokes only
  enable_firewall    = false  # Hub manages firewall
  enable_bastion     = false  # Hub manages bastion
  enable_private_dns = false  # Hub manages DNS

  # Deploy 2 spokes for staging
  spoke_count = 2

  # Compute configuration
  vm_size                   = "Standard_B1s"
  enable_vm_auto_shutdown   = true
  vm_shutdown_time         = "2000"  # Later shutdown for staging

  # Storage configuration
  storage_account_tier     = "Standard"
  storage_replication_type = "LRS"

  # Database configuration
  enable_sql_database = true
  sql_database_sku   = "S0"
  enable_cosmos_db   = false

  additional_tags = {
    Environment = "Staging"
    Workspace   = "Spokes-Staging"
    Purpose     = "Pre-production Testing"
  }
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

