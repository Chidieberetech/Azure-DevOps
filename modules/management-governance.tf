#================================================
# MANAGEMENT AND GOVERNANCE SERVICES
#================================================

# Azure Policy Assignment
resource "azurerm_management_group_policy_assignment" "main" {
  count                = var.enable_policy ? 1 : 0
  name                 = "policy-${local.resource_prefix}-${format("%03d", 1)}"
  management_group_id  = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e3576e28-8b17-4677-84c3-db2990658d64"
  description          = "Policy assignment for ${local.resource_prefix}"
  display_name         = "Require Environment Tag"

  parameters = jsonencode({
    tagName = {
      value = "Environment"
    }
    tagValue = {
      value = var.environment
    }
  })
}

# Management Group (for enterprise governance)
resource "azurerm_management_group" "main" {
  count        = var.enable_management_group ? 1 : 0
  name         = "mg-${local.resource_prefix}"
  display_name = "Management Group - ${local.resource_prefix}"

  subscription_ids = [
    data.azurerm_client_config.current.subscription_id
  ]
}

# Storage Container for Cost Management exports
resource "azurerm_storage_container" "cost_management" {
  count                 = var.enable_cost_management ? 1 : 0
  name                  = "cost-management"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Azure Monitor Action Group for governance alerts
resource "azurerm_monitor_action_group" "governance" {
  count               = var.enable_governance_alerts ? 1 : 0
  name                = "ag-${local.resource_prefix}-governance"
  resource_group_name = azurerm_resource_group.management.name
  short_name          = "gov-alerts"

  email_receiver {
    name          = "admin-email"
    email_address = var.governance_alert_email
  }

  tags = local.common_tags
}

# Azure Monitor Metric Alert for resource compliance
resource "azurerm_monitor_metric_alert" "compliance" {
  count               = var.enable_governance_alerts ? 1 : 0
  name                = "alert-${local.resource_prefix}-compliance"
  resource_group_name = azurerm_resource_group.management.name
  scopes              = [azurerm_resource_group.spokes[0].id]
  description         = "Alert for policy compliance violations"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.PolicyInsights/PolicyStates"
    metric_name      = "NonCompliantResources"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.governance[0].id
  }

  tags = local.common_tags
}

# Application Insights for governance monitoring
resource "azurerm_application_insights" "governance" {
  count               = var.enable_governance_monitoring ? 1 : 0
  name                = "appi-${local.resource_prefix}-gov"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  application_type    = "web"
  workspace_id        = var.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null

  tags = local.common_tags
}

# Custom Role Definition for Governance
resource "azurerm_role_definition" "governance_reader" {
  count              = var.enable_custom_governance_roles ? 1 : 0
  role_definition_id = uuidv5("dns", "governance-reader-${local.resource_prefix}")
  name               = "Governance Reader - ${local.resource_prefix}"
  scope              = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  description        = "Custom role for governance and compliance reading"

  permissions {
    actions = [
      "Microsoft.Authorization/policyAssignments/read",
      "Microsoft.Authorization/policyDefinitions/read",
      "Microsoft.PolicyInsights/policyStates/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Security/assessments/read",
      "Microsoft.CostManagement/exports/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  ]
}
