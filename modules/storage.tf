#================================================
# STORAGE SERVICES
#================================================


# Storage Container for logs and diagnostics
resource "azurerm_storage_container" "logs" {
  name               = "logs"
  storage_account_id = azurerm_storage_account.main.id
}

# Storage Container for backups
resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_id = azurerm_storage_account.main.id
}

