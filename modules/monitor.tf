#================================================
# AZURE MONITOR AND OBSERVABILITY
#================================================

# Log Analytics Workspace (Primary monitoring hub)
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "law-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days

  # Data export configuration
  daily_quota_gb = var.log_analytics_daily_quota_gb

  tags = local.common_tags
}

# Application Insights for application monitoring
resource "azurerm_application_insights" "main" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "appi-${local.resource_prefix}-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  workspace_id        = azurerm_log_analytics_workspace.main[0].id
  application_type    = "web"

  # Retention settings
  retention_in_days = var.app_insights_retention_days

  # Sampling settings
  sampling_percentage = var.app_insights_sampling_percentage

  tags = local.common_tags
}

# Data Collection Rules for VM monitoring
resource "azurerm_monitor_data_collection_rule" "vm_insights" {
  count               = var.enable_monitoring && var.enable_vm_monitoring ? 1 : 0
  name                = "dcr-${local.resource_prefix}-vm-insights"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
      name                  = "destination-log"
    }
  }

  data_flow {
    streams      = ["Microsoft-VMInsights-Performance", "Microsoft-VMInsights-Map"]
    destinations = ["destination-log"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-VMInsights-Performance"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\VmInsights\\DetailedMetrics"
      ]
      name = "VMInsightsPerfCounters"
    }
  }

  tags = local.common_tags
}

# Action Group for alerting
resource "azurerm_monitor_action_group" "main" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "ag-${local.resource_prefix}-alerts"
  resource_group_name = azurerm_resource_group.spokes[0].name
  short_name          = "alerts"

  # Email notifications
  dynamic "email_receiver" {
    for_each = var.alert_email_addresses
    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }

  # SMS notifications
  dynamic "sms_receiver" {
    for_each = var.alert_sms_numbers
    content {
      name         = "sms-${sms_receiver.key}"
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  # Webhook notifications
  dynamic "webhook_receiver" {
    for_each = var.alert_webhooks
    content {
      name        = "webhook-${webhook_receiver.key}"
      service_uri = webhook_receiver.value
    }
  }

  tags = local.common_tags
}

# Critical Infrastructure Alerts
resource "azurerm_monitor_metric_alert" "high_cpu" {
  count               = var.enable_monitoring && var.enable_infrastructure_alerts ? 1 : 0
  name                = "alert-${local.resource_prefix}-high-cpu"
  resource_group_name = azurerm_resource_group.spokes[0].name
  scopes              = [azurerm_resource_group.spokes[0].id]
  description         = "Alert when CPU usage is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

resource "azurerm_monitor_metric_alert" "high_memory" {
  count               = var.enable_monitoring && var.enable_infrastructure_alerts ? 1 : 0
  name                = "alert-${local.resource_prefix}-high-memory"
  resource_group_name = azurerm_resource_group.spokes[0].name
  scopes              = [azurerm_resource_group.spokes[0].id]
  description         = "Alert when memory usage is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.memory_alert_threshold_bytes
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

# Application Performance Alerts
resource "azurerm_monitor_metric_alert" "app_response_time" {
  count               = var.enable_monitoring && var.enable_app_service && var.enable_application_alerts ? 1 : 0
  name                = "alert-${local.resource_prefix}-app-response-time"
  resource_group_name = azurerm_resource_group.spokes[0].name
  scopes              = [azurerm_linux_web_app.main[0].id]
  description         = "Alert when application response time is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "AverageResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.response_time_alert_threshold_seconds
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

resource "azurerm_monitor_metric_alert" "app_error_rate" {
  count               = var.enable_monitoring && var.enable_app_service && var.enable_application_alerts ? 1 : 0
  name                = "alert-${local.resource_prefix}-app-error-rate"
  resource_group_name = azurerm_resource_group.spokes[0].name
  scopes              = [azurerm_linux_web_app.main[0].id]
  description         = "Alert when application error rate is high"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.error_rate_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

# Database Monitoring Alerts
resource "azurerm_monitor_metric_alert" "database_cpu" {
  count               = var.enable_monitoring && var.enable_sql_database && var.enable_database_alerts ? 1 : 0
  name                = "alert-${local.resource_prefix}-db-cpu"
  resource_group_name = azurerm_resource_group.spokes[0].name
  scopes              = [azurerm_mssql_database.main[0].id]
  description         = "Alert when database CPU usage is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.database_cpu_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

resource "azurerm_monitor_metric_alert" "database_storage" {
  count               = var.enable_monitoring && var.enable_sql_database && var.enable_database_alerts ? 1 : 0
  name                = "alert-${local.resource_prefix}-db-storage"
  resource_group_name = azurerm_resource_group.spokes[0].name
  scopes              = [azurerm_mssql_database.main[0].id]
  description         = "Alert when database storage usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.database_storage_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

# Network Security Monitoring
resource "azurerm_monitor_metric_alert" "ddos_attack" {
  count               = var.enable_monitoring && var.enable_ddos_protection && var.enable_security_alerts && var.enable_firewall ? 1 : 0
  name                = "alert-${local.resource_prefix}-ddos-attack"
  resource_group_name = azurerm_resource_group.spokes[0].name
  scopes              = [azurerm_public_ip.firewall[0].id]
  description         = "Alert when DDoS attack is detected"
  severity            = 0
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/publicIPAddresses"
    metric_name      = "IfUnderDDoSAttack"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

# Workbook for detailed analysis
resource "azurerm_application_insights_workbook" "infrastructure" {
  count               = var.enable_monitoring && var.enable_monitoring_workbooks ? 1 : 0
  name                = "workbook-${local.resource_prefix}-infrastructure"
  resource_group_name = azurerm_resource_group.spokes[0].name
  location            = azurerm_resource_group.spokes[0].location
  display_name        = "Infrastructure Monitoring Workbook"

  data_json = templatefile("${path.module}/templates/infrastructure-workbook.json.tpl", {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id
    subscription_id           = data.azurerm_client_config.current.subscription_id
    resource_group_name       = azurerm_resource_group.spokes[0].name
  })

  tags = local.common_tags
}

#================================================
# DIAGNOSTIC SETTINGS
#================================================

# Resource Group Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "resource_group" {
  count                      = var.enable_monitoring ? 1 : 0
  name                       = "diag-${local.resource_prefix}-rg"
  target_resource_id         = azurerm_resource_group.spokes[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Recommendation"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Autoscale"
  }

  enabled_log {
    category = "ResourceHealth"
  }

  enabled_log {
    category = "AllMetrics"
  }
}

# Network Security Group Diagnostic Settings - Removed due to missing NSG reference
# resource "azurerm_monitor_diagnostic_setting" "nsg" {
#   # This resource is commented out because the referenced NSG doesn't exist
#   # To enable this, ensure the hub_firewall NSG is created in the security.tf file
# }

# Virtual Network Diagnostic Settings - Fixed metric block and references
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  count                      = var.enable_monitoring ? 1 : 0
  name                       = "diag-${local.resource_prefix}-vnet"
  target_resource_id         = azurerm_virtual_network.spokes[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  # Fixed: Replace deprecated metric block with enabled_log
  enabled_log {
    category = "AllMetrics"
  }
}

# Application Gateway Diagnostic Settings - Commented out due to missing App Gateway resource
# resource "azurerm_monitor_diagnostic_setting" "app_gateway" {
#   count                      = var.enable_monitoring && var.enable_app_gateway ? 1 : 0
#   name                       = "diag-${local.resource_prefix}-appgw"
#   target_resource_id         = azurerm_application_gateway.main[0].id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id
#
#   enabled_log {
#     category = "ApplicationGatewayAccessLog"
#   }
#
#   enabled_log {
#     category = "ApplicationGatewayPerformanceLog"
#   }
#
#   enabled_log {
#     category = "ApplicationGatewayFirewallLog"
#   }
#
#   # Fixed: Replace deprecated metric block with enabled_log
#   enabled_log {
#     category = "AllMetrics"
#   }
# }

# Key Vault Diagnostic Settings - Fixed metric block
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count                      = var.enable_monitoring && var.enable_key_vault ? 1 : 0
  name                       = "diag-${local.resource_prefix}-kv"
  target_resource_id         = azurerm_key_vault.main[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  # Fixed: Replace deprecated metric block with enabled_log
  enabled_log {
    category = "AllMetrics"
  }
}

#================================================
# SECURITY AND COMPLIANCE MONITORING
#================================================

# Security Center Assessment Automation
resource "azurerm_security_center_auto_provisioning" "main" {
  count          = var.enable_monitoring && var.enable_security_center ? 1 : 0
  auto_provision = "On"
}

# Security Center Workspace
resource "azurerm_security_center_workspace" "main" {
  count        = var.enable_monitoring && var.enable_security_center ? 1 : 0
  scope        = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  workspace_id = azurerm_log_analytics_workspace.main[0].id
}

# Log Analytics Solutions for enhanced monitoring
resource "azurerm_log_analytics_solution" "security" {
  count                 = var.enable_monitoring && var.enable_security_monitoring ? 1 : 0
  solution_name         = "Security"
  location              = azurerm_resource_group.spokes[0].location
  resource_group_name   = azurerm_resource_group.spokes[0].name
  workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
  workspace_name        = azurerm_log_analytics_workspace.main[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Security"
  }

  tags = local.common_tags
}

resource "azurerm_log_analytics_solution" "update_management" {
  count                 = var.enable_monitoring && var.enable_update_management ? 1 : 0
  solution_name         = "Updates"
  location              = azurerm_resource_group.spokes[0].location
  resource_group_name   = azurerm_resource_group.spokes[0].name
  workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
  workspace_name        = azurerm_log_analytics_workspace.main[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Updates"
  }

  tags = local.common_tags
}

resource "azurerm_log_analytics_solution" "change_tracking" {
  count                 = var.enable_monitoring && var.enable_change_tracking ? 1 : 0
  solution_name         = "ChangeTracking"
  location              = azurerm_resource_group.spokes[0].location
  resource_group_name   = azurerm_resource_group.spokes[0].name
  workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
  workspace_name        = azurerm_log_analytics_workspace.main[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ChangeTracking"
  }

  tags = local.common_tags
}

#================================================
# COST MONITORING
#================================================

# Budget for cost monitoring
resource "azurerm_consumption_budget_resource_group" "main" {
  count           = var.enable_monitoring && var.enable_cost_monitoring ? 1 : 0
  name            = "budget-${local.resource_prefix}"
  resource_group_id = azurerm_resource_group.spokes[0].id

  amount     = var.monthly_budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
    end_date   = formatdate("YYYY-MM-01'T'00:00:00'Z'", timeadd(timestamp(), "8760h")) # 1 year
  }

  filter {
    dimension {
      name = "ResourceGroupName"
      values = [
        azurerm_resource_group.spokes[0].name,
      ]
    }
  }

  notification {
    enabled   = true
    threshold = 80
    operator  = "EqualTo"

    contact_emails = var.budget_alert_emails
  }

  notification {
    enabled   = true
    threshold = 100
    operator  = "EqualTo"

    contact_emails = var.budget_alert_emails
  }

  depends_on = [azurerm_resource_group.spokes]
}

#================================================
# PRIVATE ENDPOINTS FOR MONITORING
#================================================

# Private Endpoint for Log Analytics - Fixed references
resource "azurerm_private_endpoint" "log_analytics" {
  count               = var.enable_monitoring && var.enable_private_endpoints ? 1 : 0
  name                = "pep-${local.resource_prefix}-law-${format("%03d", 1)}"
  location            = azurerm_resource_group.spokes[0].location
  resource_group_name = azurerm_resource_group.spokes[0].name
  subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

  private_service_connection {
    name                           = "psc-log-analytics"
    private_connection_resource_id = azurerm_log_analytics_workspace.main[0].id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.monitor[0].id]
  }

  tags = local.common_tags
}

# Private DNS Zone for Azure Monitor
resource "azurerm_private_dns_zone" "monitor" {
  count               = var.enable_monitoring && var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.monitor.azure.com"
  resource_group_name = azurerm_resource_group.spokes[0].name

  tags = local.common_tags
}

# Fixed: Use spokes VNet instead of non-existent spoke_alpha
resource "azurerm_private_dns_zone_virtual_network_link" "monitor" {
  count                 = var.enable_monitoring && var.enable_private_endpoints ? 1 : 0
  name                  = "monitor-dns-link"
  resource_group_name   = azurerm_resource_group.spokes[0].name
  private_dns_zone_name = azurerm_private_dns_zone.monitor[0].name
  virtual_network_id    = azurerm_virtual_network.spokes[0].id
  registration_enabled  = false

  tags = local.common_tags
}
