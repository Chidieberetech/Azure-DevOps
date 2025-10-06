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

# Additional Action Groups for different severity levels
resource "azurerm_monitor_action_group" "critical" {
  count               = var.enable_monitoring && var.enable_advanced_alerting ? 1 : 0
  name                = "ag-${local.resource_prefix}-critical-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.management.name
  short_name          = "crit-ag"

  dynamic "email_receiver" {
    for_each = var.critical_alert_emails
    content {
      name          = "critical-email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }

  dynamic "sms_receiver" {
    for_each = var.critical_alert_sms
    content {
      name         = "critical-sms-${sms_receiver.key}"
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.critical_alert_webhooks
    content {
      name                    = "critical-webhook-${webhook_receiver.key}"
      service_uri             = webhook_receiver.value
      use_common_alert_schema = true
    }
  }

  tags = local.common_tags
}

resource "azurerm_monitor_action_group" "warning" {
  count               = var.enable_monitoring && var.enable_advanced_alerting ? 1 : 0
  name                = "ag-${local.resource_prefix}-warning-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.management.name
  short_name          = "warn-ag"

  dynamic "email_receiver" {
    for_each = var.warning_alert_emails
    content {
      name          = "warning-email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }

  tags = local.common_tags
}

#================================================
# INFRASTRUCTURE MONITORING ALERTS
#================================================

# VM CPU Usage Alert
resource "azurerm_monitor_metric_alert" "vm_cpu_high" {
  count               = var.enable_monitoring && var.enable_infrastructure_alerts && var.spoke_count > 0 ? var.spoke_count : 0
  name                = "vm-cpu-high-${local.spoke_names[count.index]}"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_windows_virtual_machine.spoke_alpha_vm[count.index].id]
  description         = "Alert when VM CPU usage is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.vm_cpu_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

# VM Memory Usage Alert
resource "azurerm_monitor_metric_alert" "vm_memory_low" {
  count               = var.enable_monitoring && var.enable_infrastructure_alerts && var.spoke_count > 0 ? var.spoke_count : 0
  name                = "vm-memory-low-${local.spoke_names[count.index]}"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_windows_virtual_machine.spoke_alpha_vm[count.index].id]
  description         = "Alert when VM available memory is low"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.vm_memory_alert_threshold_bytes
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

# Storage Account Availability Alert
resource "azurerm_monitor_metric_alert" "storage_availability" {
  count               = var.enable_monitoring && var.enable_infrastructure_alerts ? 1 : 0
  name                = "storage-availability-low"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_storage_account.main.id]
  description         = "Alert when storage account availability is low"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.storage_availability_threshold
  }

  action {
    action_group_id = var.enable_advanced_alerting ? azurerm_monitor_action_group.critical[0].id : azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

# Key Vault Availability Alert
resource "azurerm_monitor_metric_alert" "keyvault_availability" {
  count               = var.enable_monitoring && var.enable_infrastructure_alerts && var.enable_key_vault ? 1 : 0
  name                = "keyvault-availability-low"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_key_vault.main.id]
  description         = "Alert when Key Vault availability is low"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.keyvault_availability_threshold
  }

  action {
    action_group_id = var.enable_advanced_alerting ? azurerm_monitor_action_group.critical[0].id : azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

#================================================
# APPLICATION MONITORING ALERTS
#================================================

# Application Insights Response Time Alert
resource "azurerm_monitor_metric_alert" "app_response_time" {
  count               = var.enable_monitoring && var.enable_application_alerts && var.enable_app_service ? 1 : 0
  name                = "app-response-time-high"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_linux_web_app.main[0].id]
  description         = "Alert when application response time is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HttpResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.app_response_time_threshold_seconds
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

# Application HTTP Error Rate Alert
resource "azurerm_monitor_metric_alert" "app_error_rate" {
  count               = var.enable_monitoring && var.enable_application_alerts && var.enable_app_service ? 1 : 0
  name                = "app-error-rate-high"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_linux_web_app.main[0].id]
  description         = "Alert when application error rate is high"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.app_error_rate_threshold
  }

  action {
    action_group_id = var.enable_advanced_alerting ? azurerm_monitor_action_group.critical[0].id : azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

#================================================
# DATABASE MONITORING ALERTS
#================================================

# SQL Database CPU Alert
resource "azurerm_monitor_metric_alert" "sql_cpu_high" {
  count               = var.enable_monitoring && var.enable_database_alerts && var.enable_sql_database ? 1 : 0
  name                = "sql-cpu-high"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_mssql_database.main[0].id]
  description         = "Alert when SQL Database CPU usage is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.sql_cpu_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

# SQL Database Storage Alert
resource "azurerm_monitor_metric_alert" "sql_storage_high" {
  count               = var.enable_monitoring && var.enable_database_alerts && var.enable_sql_database ? 1 : 0
  name                = "sql-storage-high"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_mssql_database.main[0].id]
  description         = "Alert when SQL Database storage usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.sql_storage_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

#================================================
# CONTAINER MONITORING ALERTS
#================================================

# AKS Node CPU Alert
resource "azurerm_monitor_metric_alert" "aks_node_cpu" {
  count               = var.enable_monitoring && var.enable_infrastructure_alerts && var.enable_containers && var.enable_aks ? 1 : 0
  name                = "aks-node-cpu-high"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_kubernetes_cluster.main[0].id]
  description         = "Alert when AKS node CPU usage is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.aks_cpu_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

# AKS Node Memory Alert
resource "azurerm_monitor_metric_alert" "aks_node_memory" {
  count               = var.enable_monitoring && var.enable_infrastructure_alerts && var.enable_containers && var.enable_aks ? 1 : 0
  name                = "aks-node-memory-high"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_kubernetes_cluster.main[0].id]
  description         = "Alert when AKS node memory usage is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.aks_memory_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

#================================================
# SECURITY MONITORING ALERTS
#================================================

# Key Vault Unauthorized Access Alert
resource "azurerm_monitor_metric_alert" "keyvault_unauthorized" {
  count               = var.enable_monitoring && var.enable_security_alerts && var.enable_key_vault ? 1 : 0
  name                = "keyvault-unauthorized-access"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_key_vault.main.id]
  description         = "Alert on unauthorized Key Vault access attempts"
  severity            = 0
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = false

  criteria {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = "ServiceApiResult"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5

    dimension {
      name     = "StatusCode"
      operator = "Include"
      values   = ["403", "401"]
    }
  }

  action {
    action_group_id = var.enable_advanced_alerting ? azurerm_monitor_action_group.critical[0].id : azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

# Firewall Threat Detection Alert
resource "azurerm_monitor_metric_alert" "firewall_threats" {
  count               = var.enable_monitoring && var.enable_security_alerts && var.enable_firewall ? 1 : 0
  name                = "firewall-threat-detected"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_firewall.main[0].id]
  description         = "Alert when firewall detects threats"
  severity            = 0
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = false

  criteria {
    metric_namespace = "Microsoft.Network/azureFirewalls"
    metric_name      = "ThreatIntelHits"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = var.enable_advanced_alerting ? azurerm_monitor_action_group.critical[0].id : azurerm_monitor_action_group.main[0].id
  }

  tags = local.common_tags
}

#================================================
# COST MONITORING ALERTS
#================================================

# Budget Alert
resource "azurerm_consumption_budget_subscription" "main" {
  count           = var.enable_monitoring && var.enable_cost_monitoring ? 1 : 0
  name            = "budget-${local.resource_prefix}"
  subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"

  amount     = var.monthly_budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
    end_date   = formatdate("YYYY-MM-01'T'00:00:00'Z'", timeadd(timestamp(), "8760h"))
  }

  dynamic "notification" {
    for_each = var.budget_alert_thresholds
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Actual"

      contact_emails = var.budget_alert_emails
    }
  }

  dynamic "notification" {
    for_each = var.budget_forecast_thresholds
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Forecasted"

      contact_emails = var.budget_alert_emails
    }
  }
}

#================================================
# LOG ANALYTICS SOLUTIONS
#================================================

# VM Insights Solution
resource "azurerm_log_analytics_solution" "vm_insights" {
  count                 = var.enable_monitoring && var.enable_vm_monitoring ? 1 : 0
  solution_name         = "VMInsights"
  location              = azurerm_resource_group.management.location
  resource_group_name   = azurerm_resource_group.management.name
  workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
  workspace_name        = azurerm_log_analytics_workspace.main[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }

  tags = local.common_tags
}

# Container Insights Solution
resource "azurerm_log_analytics_solution" "container_insights" {
  count                 = var.enable_monitoring && var.enable_containers && var.enable_aks ? 1 : 0
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.management.location
  resource_group_name   = azurerm_resource_group.management.name
  workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
  workspace_name        = azurerm_log_analytics_workspace.main[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = local.common_tags
}

# Security Center Solution
resource "azurerm_log_analytics_solution" "security_center" {
  count                 = var.enable_monitoring && var.enable_security_center ? 1 : 0
  solution_name         = "Security"
  location              = azurerm_resource_group.management.location
  resource_group_name   = azurerm_resource_group.management.name
  workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
  workspace_name        = azurerm_log_analytics_workspace.main[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Security"
  }

  tags = local.common_tags
}

#================================================
# MONITORING WORKBOOKS
#================================================

# Infrastructure Overview Workbook
resource "azurerm_application_insights_workbook" "infrastructure" {
  count               = var.enable_monitoring && var.enable_monitoring_workbooks ? 1 : 0
  name                = "workbook-infrastructure-${local.resource_prefix}"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location
  display_name        = "Infrastructure Overview - ${local.resource_prefix}"
  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type = 1
        content = {
          json = "# Infrastructure Overview Dashboard\n\nThis workbook provides an overview of your Azure infrastructure health and performance."
        }
      }
    ]
  })

  tags = local.common_tags
}

#================================================
# DIAGNOSTIC SETTINGS
#================================================

# Activity Log Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  count                      = var.enable_monitoring ? 1 : 0
  name                       = "diag-activity-log-${local.resource_prefix}"
  target_resource_id         = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  dynamic "enabled_log" {
    for_each = var.activity_log_categories
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }
}

# Key Vault Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count                      = var.enable_monitoring && var.enable_key_vault ? 1 : 0
  name                       = "diag-kv-${local.resource_prefix}"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Storage Account Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "storage" {
  count                      = var.enable_monitoring ? 1 : 0
  name                       = "diag-st-${local.resource_prefix}"
  target_resource_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  metric {
    category = "Transaction"
    enabled  = true
  }

  metric {
    category = "Capacity"
    enabled  = true
  }
}
