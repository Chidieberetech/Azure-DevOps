# Azure Hub and Spoke Infrastructure - Production Environment
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-prod-we"
    storage_account_name = "sttfstateprodwe"
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

# Data sources
data "azurerm_client_config" "current" {}

# Resource Groups
resource "azurerm_resource_group" "hub" {
  name     = var.hub_resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "spoke1" {
  name     = var.spoke1_resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "spoke2" {
  name     = var.spoke2_resource_group_name
  location = var.location
  tags     = var.tags
}

# Hub Network
module "hub_network" {
  source = "../../modules/network/hub"

  resource_group_name = azurerm_resource_group.hub.name
  location           = azurerm_resource_group.hub.location
  hub_vnet_name      = var.hub_vnet_name
  hub_address_space  = var.hub_address_space
  tags               = var.tags
}

# Spoke Networks
module "spoke1_network" {
  source = "../../modules/network/spoke"

  resource_group_name    = azurerm_resource_group.spoke1.name
  location              = azurerm_resource_group.spoke1.location
  spoke_vnet_name       = var.spoke1_vnet_name
  spoke_address_space   = var.spoke1_address_space
  hub_vnet_id           = module.hub_network.vnet_id
  hub_resource_group    = azurerm_resource_group.hub.name
  firewall_private_ip   = module.firewall.private_ip_address
  tags                  = var.tags
}

module "spoke2_network" {
  source = "../../modules/network/spoke"

  resource_group_name    = azurerm_resource_group.spoke2.name
  location              = azurerm_resource_group.spoke2.location
  spoke_vnet_name       = var.spoke2_vnet_name
  spoke_address_space   = var.spoke2_address_space
  hub_vnet_id           = module.hub_network.vnet_id
  hub_resource_group    = azurerm_resource_group.hub.name
  firewall_private_ip   = module.firewall.private_ip_address
  tags                  = var.tags
}

# Key Vault
module "key_vault" {
  source = "../../modules/security/keyvault"

  resource_group_name         = azurerm_resource_group.hub.name
  location                   = azurerm_resource_group.hub.location
  key_vault_name             = var.key_vault_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  object_id                  = data.azurerm_client_config.current.object_id
  private_endpoint_subnet_id = module.hub_network.private_endpoint_subnet_id
  tags                       = var.tags
}

# Azure Firewall
module "firewall" {
  source = "../../modules/security/firewall"

  resource_group_name      = azurerm_resource_group.hub.name
  location                = azurerm_resource_group.hub.location
  firewall_name           = var.firewall_name
  firewall_subnet_id      = module.hub_network.firewall_subnet_id
  tags                    = var.tags
}

# Azure Bastion
module "bastion" {
  source = "../../modules/security/bastion"

  resource_group_name    = azurerm_resource_group.hub.name
  location              = azurerm_resource_group.hub.location
  bastion_name          = var.bastion_name
  bastion_subnet_id     = module.hub_network.bastion_subnet_id
  tags                  = var.tags
}

# Virtual Machines in Spoke 1
module "spoke1_vm" {
  source = "../../modules/compute/vm"

  resource_group_name = azurerm_resource_group.spoke1.name
  location           = azurerm_resource_group.spoke1.location
  vm_name            = var.spoke1_vm_name
  subnet_id          = module.spoke1_network.workload_subnet_id
  key_vault_id       = module.key_vault.key_vault_id
  admin_username     = var.admin_username
  vm_size            = var.vm_size
  tags               = var.tags
}

# Virtual Machines in Spoke 2
module "spoke2_vm" {
  source = "../../modules/compute/vm"

  resource_group_name = azurerm_resource_group.spoke2.name
  location           = azurerm_resource_group.spoke2.location
  vm_name            = var.spoke2_vm_name
  subnet_id          = module.spoke2_network.workload_subnet_id
  key_vault_id       = module.key_vault.key_vault_id
  admin_username     = var.admin_username
  vm_size            = var.vm_size
  tags               = var.tags
}

# Storage Account
module "storage" {
  source = "../../modules/storage"

  resource_group_name         = azurerm_resource_group.spoke1.name
  location                   = azurerm_resource_group.spoke1.location
  storage_account_name       = var.storage_account_name
  private_endpoint_subnet_id = module.spoke1_network.private_endpoint_subnet_id
  tags                       = var.tags
}

# SQL Database
module "sql_database" {
  source = "../../modules/database"

  resource_group_name         = azurerm_resource_group.spoke1.name
  location                   = azurerm_resource_group.spoke1.location
  sql_server_name            = var.sql_server_name
  database_name              = var.database_name
  admin_username             = var.sql_admin_username
  key_vault_id               = module.key_vault.key_vault_id
  private_endpoint_subnet_id = module.spoke1_network.private_endpoint_subnet_id
  tags                       = var.tags
}
