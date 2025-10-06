#================================================
# MONITORING AND ALERTING
#================================================

# Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "ag-${local.resource_prefix}-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.management.name
  short_name          = "alert-ag"

  email_receiver {
    name          = "admin-email"
    email_address = var.admin_email_address
  }

  sms_receiver {
    name         = "admin-sms"
    country_code = "1"
    phone_number = var.admin_phone_number
  }

  tags = local.common_tags
}
