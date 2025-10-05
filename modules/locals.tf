# Local Values and Computed Data
locals {
  common_tags = {
    Environment  = var.environment
    Project      = "TRL-HubSpoke"
    Organization = "TRL"
    ManagedBy    = "Terraform"
    CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
  }

  # Environment abbreviations
  env_abbr = {
    dev     = "DEV"
    staging = "STG"
    prod    = "PRD"
  }

  # Location abbreviations
  location_abbr = {
    "West Europe"     = "WEU"
    "East US"         = "EUS"
    "North Europe"    = "NEU"
    "Central US"      = "CUS"
  }

  # Hub resource group name as specified
  hub_resource_group_name = "RG-TRL-Hub-weu"

  # Resource naming convention: {resource-type}-{ENV}-{LOCATION}-{purpose}-{instance}
  resource_prefix = "${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}"

