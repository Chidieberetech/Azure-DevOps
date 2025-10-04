# Hub Workspace Configuration
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
    key                 = "hub.terraform.tfstate"
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
  environment     = "prod"
  location        = "West Europe"
  subscription_id = var.subscription_id

  # Network configuration
  enable_firewall     = true
  enable_bastion      = true
  enable_private_dns  = true

  # Security configuration
  enable_key_vault_soft_delete = true

  # Only deploy hub components (no spokes in this workspace)
  spoke_count = 0

  # Disable compute and database for hub-only deployment
  enable_sql_database = false
  enable_cosmos_db    = false

  additional_tags = {
    Workspace = "Hub"
    Purpose   = "Shared Services"
  }
}
