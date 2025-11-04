# Production Environment Configuration
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
# Azure Provider Configuration

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false  # Service principal lacks purge permission
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = var.subscription_id
}

# Data sources for hub infrastructure
data "terraform_remote_state" "hub" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.backendResourceGroupName
    storage_account_name = var.backendStorageAccountName
    container_name       = var.backendContainerName
    key                  = var.hubBackendKey
  }
}

# Spoke infrastructure for production environment
module "spoke_infrastructure" {
  source = "../../../modules"

  # Environment configuration
  environment     = var.environment
  location        = var.location
  subscription_id = var.subscription_id

  # Network configuration - spokes only
  enable_firewall    = var.enable_firewall
  enable_bastion     = var.enable_bastion
  enable_private_dns = var.enable_private_dns

  # Deploy spokes
  spoke_count = var.spoke_count

  # Compute configuration
  vm_size                 = var.vm_size
  admin_username          = var.admin_username
  admin_password          = var.admin_password
  enable_vm_auto_shutdown = var.enable_vm_auto_shutdown
  vm_shutdown_time        = var.vm_shutdown_time
  enable_vm_monitoring    = var.enable_vm_monitoring

  # Storage configuration
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_replication_type

  # Database configuration
  enable_sql_database = var.enable_sql_database
  sql_database_sku    = var.sql_database_sku
  enable_cosmos_db    = var.enable_cosmos_db

  # Monitoring configuration
  enable_monitoring     = var.enable_monitoring
  log_retention_days    = var.log_retention_days
  admin_email_address   = var.owner_email
  admin_phone_number    = var.admin_phone_number

  # Tags for resources - Limited to 2 additional tags to stay within Azure's 15 tag limit
  # Base common_tags already include: Environment, CostCenter, BusinessUnit, Owner, etc.
  additional_tags = merge(var.additional_tags, {
    Workspace        = "Spoke-Prod"
    CriticalityLevel = "High"
  })
}

# Random string for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# SFTP Storage Account VNet
resource "azurerm_virtual_network" "sftp_vnet" {
  count               = var.enable_sftp_storage ? 1 : 0
  name                = "vnet-${var.environment}-sftp-${replace(var.location, " ", "")}"
  address_space       = var.sftp_vnet_address_space
  location            = var.location
  resource_group_name = "rg-trl-${var.environment}-alpha-001"

  tags = merge(var.additional_tags, {
    Purpose     = "SFTP Storage Network"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# SFTP Storage Account Subnet
resource "azurerm_subnet" "sftp_subnet" {
  count                = var.enable_sftp_storage ? 1 : 0
  name                 = "snet-${var.environment}-sftp"
  resource_group_name  = "rg-trl-${var.environment}-alpha-001"
  virtual_network_name = azurerm_virtual_network.sftp_vnet[0].name
  address_prefixes     = var.sftp_subnet_prefix
}

# SFTP Storage Account
resource "azurerm_storage_account" "sftp" {
  count                    = var.enable_sftp_storage ? 1 : 0
  name                     = "st${replace(var.environment, "-", "")}sftp${random_string.suffix.result}"
  resource_group_name      = "rg-trl-${var.environment}-alpha-001"
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"

  # Enable HNS (Hierarchical Namespace) for SFTP
  is_hns_enabled = true

  # Network restrictions
  public_network_access_enabled = false

  # Minimum TLS version
  min_tls_version = "TLS1_2"

  tags = merge(var.additional_tags, {
    Purpose     = "SFTP Storage"
    Service     = "SFTP"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# SFTP Storage Account Network Rules
resource "azurerm_storage_account_network_rules" "sftp" {
  count              = var.enable_sftp_storage ? 1 : 0
  storage_account_id = azurerm_storage_account.sftp[0].id

  default_action             = "Deny"
  ip_rules                   = [var.sftp_allowed_ip] # Allowed IP
  virtual_network_subnet_ids = [azurerm_subnet.sftp_subnet[0].id]
  bypass                     = ["AzureServices"]
}

# Private Endpoint for SFTP Storage Account
resource "azurerm_private_endpoint" "sftp" {
  count               = var.enable_sftp_storage ? 1 : 0
  name                = "pep-${var.environment}-sftp"
  location            = var.location
  resource_group_name = "rg-trl-${var.environment}-alpha-001"
  subnet_id           = azurerm_subnet.sftp_subnet[0].id

  private_service_connection {
    name                           = "psc-sftp"
    private_connection_resource_id = azurerm_storage_account.sftp[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage[0].id]
  }

  tags = merge(var.additional_tags, {
    Purpose     = "SFTP Private Endpoint"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# Private DNS Zone for Storage
resource "azurerm_private_dns_zone" "storage" {
  count               = var.enable_sftp_storage ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "rg-trl-${var.environment}-alpha-001"

  tags = var.additional_tags
}

# Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  count                 = var.enable_sftp_storage ? 1 : 0
  name                  = "vnet-link-${var.environment}-storage"
  resource_group_name   = "rg-trl-${var.environment}-alpha-001"
  private_dns_zone_name = azurerm_private_dns_zone.storage[0].name
  virtual_network_id    = azurerm_virtual_network.sftp_vnet[0].id

  tags = var.additional_tags
}

# SFTP Storage Containers
resource "azurerm_storage_container" "migration" {
  count                 = var.enable_sftp_storage ? 1 : 0
  name                  = "migration"
  storage_account_id    = azurerm_storage_account.sftp[0].id
  container_access_type = "private"
}

resource "azurerm_storage_container" "archive" {
  count                 = var.enable_sftp_storage ? 1 : 0
  name                  = "archive"
  storage_account_id    = azurerm_storage_account.sftp[0].id
  container_access_type = "private"
}

# Windows VM VNet
resource "azurerm_virtual_network" "vm_vnet" {
  count               = var.enable_windows_vm ? 1 : 0
  name                = "vnet-${var.environment}-vm-${replace(var.location, " ", "")}"
  address_space       = var.vm_vnet_address_space
  location            = var.location
  resource_group_name = "rg-trl-${var.environment}-alpha-001"

  tags = merge(var.additional_tags, {
    Purpose     = "Windows VM Network"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# Windows VM Subnet
resource "azurerm_subnet" "vm_subnet" {
  count                = var.enable_windows_vm ? 1 : 0
  name                 = "snet-${var.environment}-vm"
  resource_group_name  = "rg-trl-${var.environment}-alpha-001"
  virtual_network_name = azurerm_virtual_network.vm_vnet[0].name
  address_prefixes     = var.vm_subnet_prefix
}

# Network Security Group for Windows VM
resource "azurerm_network_security_group" "vm" {
  count               = var.enable_windows_vm ? 1 : 0
  name                = "nsg-${var.environment}-vm"
  location            = var.location
  resource_group_name = "rg-trl-${var.environment}-alpha-001"

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = merge(var.additional_tags, {
    Purpose     = "Windows VM Security"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# Associate NSG with VM Subnet
resource "azurerm_subnet_network_security_group_association" "vm" {
  count                     = var.enable_windows_vm ? 1 : 0
  subnet_id                 = azurerm_subnet.vm_subnet[0].id
  network_security_group_id = azurerm_network_security_group.vm[0].id
}

# Windows VM Network Interface
resource "azurerm_network_interface" "vm" {
  count               = var.enable_windows_vm ? 1 : 0
  name                = "nic-${var.environment}-vm"
  location            = var.location
  resource_group_name = "rg-trl-${var.environment}-alpha-001"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet[0].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.additional_tags, {
    Purpose     = "Windows VM NIC"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  count               = var.enable_windows_vm ? 1 : 0
  name                = "vm-${var.environment}-win"
  resource_group_name = "rg-trl-${var.environment}-alpha-001"
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.vm[0].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  automatic_updates_enabled = true
  provision_vm_agent        = true

  tags = merge(var.additional_tags, {
    Purpose     = "Windows Server"
    OS          = "Windows Server 2019"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}