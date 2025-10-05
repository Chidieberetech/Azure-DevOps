# Provider and Terraform Version Requirements
# WARNING: AzureRM 4.0 includes breaking changes and is non-reversible
# Recommended to test in non-production environments first
# Make backups of environment and state files before upgrading

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # PRODUCTION RECOMMENDATION: Pin to stable 3.x version
      version = "= 3.116.0"

      # FOR TESTING ONLY: Uncomment below to test 4.0 features
      # version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = var.subscription_id

  # Enhanced Resource Provider Registration (4.0 feature)
  # Currently using 3.x compatible configuration
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }
    template_deployment {
      delete_nested_items_during_deletion = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    application_insights {
      disable_generated_rule = false
    }
  }
}

# Configuration for AzureRM 4.0 Migration (when ready)
# Uncomment and modify when upgrading to 4.0
/*
provider "azurerm" {
  subscription_id = var.subscription_id

  # 4.0 Enhanced Resource Provider Registration
  resource_provider_registrations = "extended"
  # Options: "none", "core", "extended"

  features {
    # ... same features as above
  }
}
*/
