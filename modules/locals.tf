# Local Values and Computed Data
locals {
  common_tags = {
    Environment  = var.environment
    Project      = "TRL-HubSpoke"
    Organization = "TRL"
    ManagedBy    = "Terraform"
    CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
  }

  # Naming convention: trl-hubspoke-{env}-{resource}-{suffix}
  resource_prefix = "trl-hubspoke-${var.environment}"

  # Network configuration
  hub_address_space    = ["10.0.0.0/16"]
  spoke1_address_space = ["10.1.0.0/16"]
  spoke2_address_space = ["10.2.0.0/16"]

  # Subnet configurations
  hub_subnets = {
    firewall_subnet     = "10.0.1.0/26"
    bastion_subnet      = "10.0.2.0/27"
    shared_services     = "10.0.3.0/24"
    private_endpoint    = "10.0.4.0/24"
  }

  spoke1_subnets = {
    workload_subnet     = "10.1.1.0/24"
    database_subnet     = "10.1.2.0/24"
    private_endpoint    = "10.1.3.0/24"
  }

  spoke2_subnets = {
    workload_subnet     = "10.2.1.0/24"
    app_service_subnet  = "10.2.2.0/24"
    private_endpoint    = "10.2.3.0/24"
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Random suffix for globally unique resources
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
