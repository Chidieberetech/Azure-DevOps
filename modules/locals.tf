#================================================
# LOCAL VALUES AND COMPUTED VARIABLES
#================================================

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Random string for unique resource naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  # Environment abbreviations
  env_abbr = {
    dev     = "dev"
    staging = "stg"
    prod    = "prd"
  }

  # Location abbreviations
  location_abbr = {
    "West Europe"      = "weu"
    "East US"          = "eus"
    "East US 2"        = "eus2"
    "Central US"       = "cus"
    "North Europe"     = "neu"
    "UK South"         = "uks"
    "Southeast Asia"   = "sea"
  }

  # Resource naming
  resource_prefix = "trl-${local.env_abbr[var.environment]}"

  # Hub resource group name
  hub_resource_group_name = "rg-trl-${local.env_abbr[var.environment]}-hub-001"

  # Spoke names
  spoke_names = ["alpha", "beta", "gamma"]

  # Common tags
  common_tags = {
    Environment       = var.environment
    Project           = "Azure.IAC.hubspoke"
    ManagedBy         = "Terraform"
    CreatedDate       = timestamp()
    CostCenter        = "IT-Infrastructure"
    Owner             = "Platform-Team"
    BusinessUnit      = "Technology"
    Application       = "Hub-Spoke-Network"
    BackupRequired    = "Yes"
    MaintenanceWindow = "Sunday-02:00-06:00-UTC"
    Compliance        = "Internal"
    DataClassification = "Internal"
    SupportLevel      = "L2"
    AutoShutdown      = var.environment == "dev" ? "Yes" : "No"
    MonitoringEnabled = "Yes"
    SecurityLevel     = "Standard"
    ProvisionedBy     = "Azure-DevOps"
    TerraformModule   = "hub-spoke-v1.0"
    ReviewDate        = formatdate("YYYY-MM-DD", timeadd(timestamp(), "8760h")) # 1 year from now
  }

  # Network address spaces
  hub_address_space = ["10.0.0.0/16"]
  spoke_alpha_address_space = ["10.1.0.0/16"]
  spoke_beta_address_space = ["10.2.0.0/16"]
  spoke_gamma_address_space = ["10.3.0.0/16"]

  # Hub subnet definitions
  hub_subnets = {
    firewall_subnet      = "10.0.1.0/26"
    bastion_subnet       = "10.0.2.0/27"
    gateway_subnet       = "10.0.3.0/27"
    shared_services      = "10.0.4.0/24"
    private_endpoint     = "10.0.5.0/24"
  }

  # Spoke Alpha subnet definitions
  spoke_alpha_subnets = {
    workload_subnet      = "10.1.1.0/24"
    vm_subnet           = "10.1.4.0/24"
    database_subnet     = "10.1.8.0/24"
    private_endpoint    = "10.1.9.0/24"
  }

  # Spoke Beta subnet definitions
  spoke_beta_subnets = {
    workload_subnet     = "10.2.1.0/24"
    vm_subnet          = "10.2.4.0/24"
    database_subnet    = "10.2.8.0/24"
    private_endpoint   = "10.2.9.0/24"
  }

  ## Spoke Gamma subnet definitions (for future use and scalability more than two spokes)
  # spoke_gamma_subnets = {
  #  workload_subnet     = "10.3.1.0/24"
  #  vm_subnet          = "10.3.4.0/24"
  #  database_subnet    = "10.3.8.0/24"
  #  private_endpoint   = "10.3.9.0/24"
  #}

}
