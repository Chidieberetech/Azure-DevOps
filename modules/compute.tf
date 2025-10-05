#================================================
# VIRTUAL MACHINES IN SPOKES
#================================================

# Data source to get Key Vault secret for VM password
data "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_secret.vm_admin_password]
}

#================================================
# SPOKE ALPHA VIRTUAL MACHINE
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
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.4.10"
  }
}

# Virtual Machine in Spoke Alpha
resource "azurerm_windows_virtual_machine" "spoke_alpha_vm" {
  count               = var.spoke_count >= 1 ? 1 : 0
  name                = "vm-${local.resource_prefix}-alpha-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = data.azurerm_key_vault_secret.vm_password.value
  tags                = local.common_tags

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.spoke_alpha_vm[0].id,
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

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diagnostics.primary_blob_endpoint
  }
}

# VM Extension for IIS (Web Server)
resource "azurerm_virtual_machine_extension" "spoke_alpha_vm_iis" {
  count                = var.spoke_count >= 1 ? 1 : 0
  name                 = "install-iis"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke_alpha_vm[0].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value \"<html><body><h1>TRL Hub-Spoke Architecture - Spoke Alpha VM</h1><p>Server: ${azurerm_windows_virtual_machine.spoke_alpha_vm[0].name}</p></body></html>\""
    }
SETTINGS

  tags = local.common_tags
}

#================================================
# SPOKE BETA VIRTUAL MACHINE
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
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.4.10"
  }
}

# Virtual Machine in Spoke Beta
resource "azurerm_windows_virtual_machine" "spoke_beta_vm" {
  count               = var.spoke_count >= 2 ? 1 : 0
  name                = "vm-${local.resource_prefix}-beta-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[1].name
  location            = azurerm_resource_group.spokes[1].location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = data.azurerm_key_vault_secret.vm_password.value
  tags                = local.common_tags

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.spoke_beta_vm[0].id,
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

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diagnostics.primary_blob_endpoint
  }
}

# VM Extension for IIS (Web Server)
resource "azurerm_virtual_machine_extension" "spoke_beta_vm_iis" {
  count                = var.spoke_count >= 2 ? 1 : 0
  name                 = "install-iis"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke_beta_vm[0].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value \"<html><body><h1>TRL Hub-Spoke Architecture - Spoke Beta VM</h1><p>Server: ${azurerm_windows_virtual_machine.spoke_beta_vm[0].name}</p></body></html>\""
    }
SETTINGS

  tags = local.common_tags
}

#================================================
# ROUTE TABLES
#================================================

# Route Table for Spoke Subnets to route traffic through firewall
resource "azurerm_route_table" "spoke_to_firewall" {
  count                         = var.spoke_count
  name                          = "rt-${local.resource_prefix}-${local.spoke_names[count.index]}-${format("%03d", 1)}"
  location                      = azurerm_resource_group.spokes[count.index].location
  resource_group_name           = azurerm_resource_group.spokes[count.index].name
  disable_bgp_route_propagation = false
  tags                          = local.common_tags

  route {
    name           = "ToFirewall"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = var.enable_firewall ? azurerm_firewall.main[0].ip_configuration[0].private_ip_address : null
  }
}

# Associate Route Table with VM Subnets
resource "azurerm_subnet_route_table_association" "spoke_alpha_vm" {
  count          = var.spoke_count >= 1 ? 1 : 0
  subnet_id      = azurerm_subnet.spoke_alpha_vm[0].id
  route_table_id = azurerm_route_table.spoke_to_firewall[0].id
}

resource "azurerm_subnet_route_table_association" "spoke_beta_vm" {
  count          = var.spoke_count >= 2 ? 1 : 0
  subnet_id      = azurerm_subnet.spoke_beta_vm[0].id
  route_table_id = azurerm_route_table.spoke_to_firewall[1].id
}
