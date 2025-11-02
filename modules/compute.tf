#================================================
# VIRTUAL MACHINES IN SPOKES
#================================================

# Data source to get Key Vault secret for VM password
data "azurerm_key_vault_secret" "vm_password" {
  count        = var.enable_vm_monitoring && var.enable_key_vault ? 1 : 0
  name         = "vm-admin-password"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_secret.vm_admin_password]
}

#================================================
# AVAILABILITY SETS FOR HIGH AVAILABILITY
#================================================

# Availability Set for Spoke Alpha VMs
resource "azurerm_availability_set" "spoke_alpha" {
  count                        = var.spoke_count >= 1 ? 1 : 0
  name                         = "avset-${local.resource_prefix}-alpha-${format("%03d", 1)}"
  location                     = azurerm_resource_group.spokes[0].location
  resource_group_name          = azurerm_resource_group.spokes[0].name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags                         = local.common_tags
}

# Availability Set for Spoke Beta VMs
resource "azurerm_availability_set" "spoke_beta" {
  count                        = var.spoke_count >= 2 ? 1 : 0
  name                         = "avset-${local.resource_prefix}-beta-${format("%03d", 1)}"
  location                     = azurerm_resource_group.spokes[1].location
  resource_group_name          = azurerm_resource_group.spokes[1].name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags                         = local.common_tags
}

#================================================
# SPOKE ALPHA VIRTUAL MACHINE (LINUX)
#================================================

# Network Interface for Spoke Alpha VM
resource "azurerm_network_interface" "spoke_alpha_vm" {
  count               = var.spoke_count >= 1 ? 1 : 0
  name                = "nic-${local.resource_prefix}-alpha-vm-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke_alpha_vm[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Linux Virtual Machine in Spoke Alpha
resource "azurerm_linux_virtual_machine" "spoke_alpha" {
  count                           = var.spoke_count >= 1 ? 1 : 0
  name                            = "vm-${local.resource_prefix}-alpha-${format("%03d", 1)}"
  location                        = azurerm_resource_group.spokes[0].location
  resource_group_name             = azurerm_resource_group.spokes[0].name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  availability_set_id             = azurerm_availability_set.spoke_alpha[0].id

  network_interface_ids = [
    azurerm_network_interface.spoke_alpha_vm[0].id,
  ]

  os_disk {
    name                 = "osdisk-${local.resource_prefix}-alpha-${format("%03d", 1)}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.main.primary_blob_endpoint
  }

  tags = merge(local.common_tags, {
    Purpose     = "Application Server"
    OS          = "Ubuntu 20.04"
    Environment = var.environment
  })
}

# Auto-shutdown schedule for Spoke Alpha VM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "spoke_alpha" {
  count              = var.spoke_count >= 1 && var.enable_vm_auto_shutdown ? 1 : 0
  virtual_machine_id = azurerm_linux_virtual_machine.spoke_alpha[0].id
  location           = azurerm_resource_group.spokes[0].location
  enabled            = true

  daily_recurrence_time = var.vm_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = local.common_tags
}

#================================================
# SPOKE BETA VIRTUAL MACHINE (LINUX)
#================================================

# Network Interface for Spoke Beta VM
resource "azurerm_network_interface" "spoke_beta_vm" {
  count               = var.spoke_count >= 2 ? 1 : 0
  name                = "nic-${local.resource_prefix}-beta-vm-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[1].location
  resource_group_name = azurerm_resource_group.spokes[1].name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke_beta_vm[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Linux Virtual Machine in Spoke Beta
resource "azurerm_linux_virtual_machine" "spoke_beta" {
  count                           = var.spoke_count >= 2 ? 1 : 0
  name                            = "vm-${local.resource_prefix}-beta-${format("%03d", 1)}"
  location                        = azurerm_resource_group.spokes[1].location
  resource_group_name             = azurerm_resource_group.spokes[1].name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  availability_set_id             = azurerm_availability_set.spoke_beta[0].id

  network_interface_ids = [
    azurerm_network_interface.spoke_beta_vm[0].id,
  ]

  os_disk {
    name                 = "osdisk-${local.resource_prefix}-beta-${format("%03d", 1)}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.main.primary_blob_endpoint
  }

  tags = merge(local.common_tags, {
    Purpose     = "Application Server"
    OS          = "Ubuntu 20.04"
    Environment = var.environment
  })
}

# Auto-shutdown schedule for Spoke Beta VM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "spoke_beta" {
  count              = var.spoke_count >= 2 && var.enable_vm_auto_shutdown ? 1 : 0
  virtual_machine_id = azurerm_linux_virtual_machine.spoke_beta[0].id
  location           = azurerm_resource_group.spokes[1].location
  enabled            = true

  daily_recurrence_time = var.vm_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = local.common_tags
}

#================================================
# VM EXTENSIONS FOR MONITORING
#================================================

# Azure Monitor Agent for Spoke Alpha VM
resource "azurerm_virtual_machine_extension" "spoke_alpha_monitor" {
  count                      = var.spoke_count >= 1 && var.enable_vm_monitoring ? 1 : 0
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.spoke_alpha[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.21"
  auto_upgrade_minor_version = true

  tags = local.common_tags
}

# Azure Monitor Agent for Spoke Beta VM
resource "azurerm_virtual_machine_extension" "spoke_beta_monitor" {
  count                      = var.spoke_count >= 2 && var.enable_vm_monitoring ? 1 : 0
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.spoke_beta[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.21"
  auto_upgrade_minor_version = true

  tags = local.common_tags
}

#================================================
# MANAGED DISKS FOR DATA
#================================================

# Data Disk for Spoke Alpha VM
resource "azurerm_managed_disk" "spoke_alpha_data" {
  count                = var.spoke_count >= 1 ? 1 : 0
  name                 = "datadisk-${local.resource_prefix}-alpha-${format("%03d", 1)}"
  location             = azurerm_resource_group.spokes[0].location
  resource_group_name  = azurerm_resource_group.spokes[0].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256

  tags = local.common_tags
}

# Attach Data Disk to Spoke Alpha VM
resource "azurerm_virtual_machine_data_disk_attachment" "spoke_alpha_data" {
  count              = var.spoke_count >= 1 ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.spoke_alpha_data[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.spoke_alpha[0].id
  lun                = 0
  caching            = "ReadWrite"
}

# Data Disk for Spoke Beta VM
resource "azurerm_managed_disk" "spoke_beta_data" {
  count                = var.spoke_count >= 2 ? 1 : 0
  name                 = "datadisk-${local.resource_prefix}-beta-${format("%03d", 1)}"
  location             = azurerm_resource_group.spokes[1].location
  resource_group_name  = azurerm_resource_group.spokes[1].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256

  tags = local.common_tags
}

# Attach Data Disk to Spoke Beta VM
resource "azurerm_virtual_machine_data_disk_attachment" "spoke_beta_data" {
  count              = var.spoke_count >= 2 ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.spoke_beta_data[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.spoke_beta[0].id
  lun                = 0
  caching            = "ReadWrite"
}
