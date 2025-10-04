# Management Workspace Configuration
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
    key                 = "management.terraform.tfstate"
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
  environment     = "prod"
  location        = "West Europe"
  subscription_id = var.subscription_id

  # Disable network components (managed by hub workspace)
  enable_firewall    = false
  enable_bastion     = false
  enable_private_dns = false

  # Only deploy management components
  spoke_count = 0

  # Enable monitoring and governance
  enable_monitoring = true

  additional_tags = {
    Workspace = "Management"
    Purpose   = "Monitoring and Governance"
  }
}
