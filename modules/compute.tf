#================================================
# VIRTUAL MACHINES
#================================================

# Data source to get Key Vault secret for VM password
data "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_secret.vm_admin_password]
}

# Network Interface for Spoke 1 VM
resource "azurerm_network_interface" "spoke1_vm" {
  count               = var.spoke_count >= 1 ? 1 : 0
  name                = "${local.resource_prefix}-nic-vm-spoke1"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_workload[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machine in Spoke 1
resource "azurerm_windows_virtual_machine" "spoke1_vm" {
  count               = var.spoke_count >= 1 ? 1 : 0
  name                = "${local.resource_prefix}-vm-spoke1"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = data.azurerm_key_vault_secret.vm_password.value
  tags                = local.common_tags

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.spoke1_vm[0].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Network Interface for Spoke 2 VM
resource "azurerm_network_interface" "spoke2_vm" {
  count               = var.spoke_count >= 2 ? 1 : 0
  name                = "${local.resource_prefix}-nic-vm-spoke2"
  location            = azurerm_resource_group.spokes[1].location
  resource_group_name = azurerm_resource_group.spokes[1].name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_workload[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machine in Spoke 2
resource "azurerm_windows_virtual_machine" "spoke2_vm" {
  count               = var.spoke_count >= 2 ? 1 : 0
  name                = "${local.resource_prefix}-vm-spoke2"
  resource_group_name = azurerm_resource_group.spokes[1].name
  location            = azurerm_resource_group.spokes[1].location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = data.azurerm_key_vault_secret.vm_password.value
  tags                = local.common_tags

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.spoke2_vm[0].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

# VM Extension for Azure Key Vault integration - Spoke 1
resource "azurerm_virtual_machine_extension" "spoke1_keyvault" {
  count                = var.spoke_count >= 1 ? 1 : 0
  name                 = "KeyVaultExtension"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke1_vm[0].id
  publisher            = "Microsoft.Azure.KeyVault"
  type                 = "KeyVaultForWindows"
  type_handler_version = "1.0"
  tags                 = local.common_tags

  settings = jsonencode({
    secretsManagementSettings = {
      observedCertificates     = []
      certificateStoreLocation = "LocalMachine"
      certificateStoreName     = "MY"
      pollingIntervalInS       = "3600"
      requireInitialSync       = true
    }
  })
}

# VM Extension for Azure Key Vault integration - Spoke 2
resource "azurerm_virtual_machine_extension" "spoke2_keyvault" {
  count                = var.spoke_count >= 2 ? 1 : 0
  name                 = "KeyVaultExtension"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke2_vm[0].id
  publisher            = "Microsoft.Azure.KeyVault"
  type                 = "KeyVaultForWindows"
  type_handler_version = "1.0"
  tags                 = local.common_tags

  settings = jsonencode({
    secretsManagementSettings = {
      observedCertificates     = []
      certificateStoreLocation = "LocalMachine"
      certificateStoreName     = "MY"
      pollingIntervalInS       = "3600"
      requireInitialSync       = true
    }
  })
}

# Auto-shutdown schedule for Spoke 1 VM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "spoke1_vm" {
  count              = var.spoke_count >= 1 && var.enable_vm_auto_shutdown ? 1 : 0
  virtual_machine_id = azurerm_windows_virtual_machine.spoke1_vm[0].id
  location           = azurerm_resource_group.spokes[0].location
  enabled            = true

  daily_recurrence_time = var.vm_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = local.common_tags
}

# Auto-shutdown schedule for Spoke 2 VM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "spoke2_vm" {
  count              = var.spoke_count >= 2 && var.enable_vm_auto_shutdown ? 1 : 0
  virtual_machine_id = azurerm_windows_virtual_machine.spoke2_vm[0].id
  location           = azurerm_resource_group.spokes[1].location
  enabled            = true

  daily_recurrence_time = var.vm_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = local.common_tags
}
