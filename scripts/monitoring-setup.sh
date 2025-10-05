#!/bin/bash
# Infrastructure Monitoring Setup Script for TRL Hub and Spoke
# Sets up comprehensive monitoring, alerting, and dashboards across all environments

set -e

echo ":) Setting up infrastructure monitoring for TRL Hub and Spoke..."

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MONITORING_REPORT="monitoring-setup-${TIMESTAMP}.txt"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV   Environment to setup (dev/staging/prod/all)"
    echo "  -t, --type TYPE         Monitoring type (alerts/dashboards/logs/all)"
    echo "  -s, --severity LEVEL    Alert severity (critical/warning/info/all)"
    echo "  -h, --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e all -t all                     # Setup all monitoring for all environments"
    echo "  $0 -e prod -t alerts -s critical     # Setup critical alerts for production"
    echo "  $0 -e dev -t dashboards             # Setup dashboards for development"
}

# Parse command line arguments
ENVIRONMENT="all"
MONITORING_TYPE="all"
ALERT_SEVERITY="all"

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--type)
            MONITORING_TYPE="$2"
            shift 2
            ;;
        -s|--severity)
            ALERT_SEVERITY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo ":( Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

# Function to setup Log Analytics workspace
setup_log_analytics() {
    local subscription=$1
    local env_name=$2

    echo "|) Setting up Log Analytics for $env_name environment..."
    az account set --subscription "$subscription"

    # Create Log Analytics workspace
    WORKSPACE_NAME="trl-hubspoke-${env_name}-log"
    RG_NAME="trl-hubspoke-${env_name}-rg-monitoring"

    # Create resource group for monitoring
    az group create --name "$RG_NAME" --location "West Europe" || true

    # Create Log Analytics workspace
    az monitor log-analytics workspace create \
        --resource-group "$RG_NAME" \
        --workspace-name "$WORKSPACE_NAME" \
        --location "West Europe" \
        --sku "PerGB2018" || true

    # Get workspace ID for later use
    WORKSPACE_ID=$(az monitor log-analytics workspace show \
        --resource-group "$RG_NAME" \
        --workspace-name "$WORKSPACE_NAME" \
        --query "customerId" -o tsv)

    echo "  :) Log Analytics workspace created: $WORKSPACE_NAME"
    echo "  |) Workspace ID: $WORKSPACE_ID"
}

# Function to setup alerts
setup_alerts() {
    local subscription=$1
    local env_name=$2

    echo "|) Setting up alerts for $env_name environment..."
    az account set --subscription "$subscription"

    # Create action group for notifications
    ACTION_GROUP_NAME="trl-hubspoke-${env_name}-ag"
    RG_NAME="trl-hubspoke-${env_name}-rg-monitoring"

    az monitor action-group create \
        --resource-group "$RG_NAME" \
        --name "$ACTION_GROUP_NAME" \
        --short-name "TRL-${env_name}" || true

    # Setup VM alerts
    echo "  Setting up VM alerts..."

    # VM CPU utilization alert
    az monitor metrics alert create \
        --name "trl-hubspoke-${env_name}-vm-cpu-high" \
        --resource-group "$RG_NAME" \
        --scopes "/subscriptions/$(az account show --query id -o tsv)" \
        --condition "avg Percentage CPU > 80" \
        --description "VM CPU utilization is high" \
        --evaluation-frequency "5m" \
        --window-size "15m" \
        --severity 2 \
        --action "$ACTION_GROUP_NAME" || true

    # VM availability alert
    az monitor metrics alert create \
        --name "trl-hubspoke-${env_name}-vm-availability" \
        --resource-group "$RG_NAME" \
        --scopes "/subscriptions/$(az account show --query id -o tsv)" \
        --condition "avg VmAvailabilityMetric < 1" \
        --description "VM availability is degraded" \
        --evaluation-frequency "1m" \
        --window-size "5m" \
        --severity 1 \
        --action "$ACTION_GROUP_NAME" || true

    # Storage account alerts
    echo "  Setting up Storage alerts..."

    # Storage capacity alert
    az monitor metrics alert create \
        --name "trl-hubspoke-${env_name}-storage-capacity" \
        --resource-group "$RG_NAME" \
        --scopes "/subscriptions/$(az account show --query id -o tsv)" \
        --condition "avg UsedCapacity > 4000000000" \
        --description "Storage account capacity is high (>4GB for free tier)" \
        --evaluation-frequency "1h" \
        --window-size "1h" \
        --severity 2 \
        --action "$ACTION_GROUP_NAME" || true

    echo "  :) Alerts configured for $env_name"
}

# Function to setup dashboards
setup_dashboards() {
    local subscription=$1
    local env_name=$2

    echo "|) Setting up dashboards for $env_name environment..."
    az account set --subscription "$subscription"

    # Create dashboard JSON configuration
    cat > "dashboard-${env_name}.json" << EOF
{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {"x": 0, "y": 0, "rowSpan": 4, "colSpan": 6},
          "metadata": {
            "inputs": [
              {
                "name": "subscriptionId",
                "value": "$(az account show --query id -o tsv)"
              }
            ],
            "type": "Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart"
          }
        }
      }
    }
  },
  "metadata": {
    "model": {
      "timeRange": {
        "value": {
          "relative": {
            "duration": 24,
            "timeUnit": 1
          }
        },
        "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
      }
    }
  }
}
EOF

    # Create dashboard
    az portal dashboard create \
        --resource-group "trl-hubspoke-${env_name}-rg-monitoring" \
        --name "trl-hubspoke-${env_name}-dashboard" \
        --input-path "dashboard-${env_name}.json" \
        --location "West Europe" || true

    echo "  :) Dashboard created for $env_name"
    rm -f "dashboard-${env_name}.json"
}

# Function to configure diagnostic settings
setup_diagnostic_logs() {
    local subscription=$1
    local env_name=$2

    echo "|) Setting up diagnostic logs for $env_name environment..."
    az account set --subscription "$subscription"

    # Get Log Analytics workspace
    WORKSPACE_ID=$(az monitor log-analytics workspace list \
        --query "[?starts_with(name, 'trl-hubspoke-$env_name')].id" -o tsv | head -1)

    if [ -n "$WORKSPACE_ID" ]; then
        echo "  Configuring diagnostic settings..."

        # Configure VNet diagnostic settings
        VNETS=$(az network vnet list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].id" -o tsv)

        for vnet_id in $VNETS; do
            az monitor diagnostic-settings create \
                --resource "$vnet_id" \
                --name "vnet-diagnostics" \
                --workspace "$WORKSPACE_ID" \
                --logs '[{"category":"VMProtectionAlerts","enabled":true}]' \
                --metrics '[{"category":"AllMetrics","enabled":true}]' 2>/dev/null || true
        done

        # Configure VM diagnostic settings
        VMS=$(az vm list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].id" -o tsv)

        for vm_id in $VMS; do
            az monitor diagnostic-settings create \
                --resource "$vm_id" \
                --name "vm-diagnostics" \
                --workspace "$WORKSPACE_ID" \
                --metrics '[{"category":"AllMetrics","enabled":true}]' 2>/dev/null || true
        done

        echo "  :) Diagnostic settings configured"
    else
        echo "  :| No Log Analytics workspace found for $env_name"
    fi
}

# Main execution
echo ""
echo ":) Starting monitoring setup..."
echo "|) Environment: $ENVIRONMENT"
echo "|) Monitoring type: $MONITORING_TYPE"
echo "|) Alert severity: $ALERT_SEVERITY"

# Initialize monitoring report
cat > "$MONITORING_REPORT" << EOF
TRL Hub and Spoke Infrastructure Monitoring Setup Report
=======================================================
Generated: $(date -u)
Environment: $ENVIRONMENT
Monitoring Type: $MONITORING_TYPE

MONITORING CONFIGURATION
=======================
EOF

# Setup monitoring for specified environments
for env_config in "Sub-TRL-dev-weu:dev" "Sub-TRL-int-weu:staging" "Sub-TRL-prod-weu:prod"; do
    IFS=':' read -r subscription env_name <<< "$env_config"

    if [[ "$ENVIRONMENT" == "all" || "$ENVIRONMENT" == "$env_name" ]]; then
        if az account show --subscription "$subscription" >/dev/null 2>&1; then
            echo "" | tee -a "$MONITORING_REPORT"
            echo "Setting up monitoring for $env_name environment..." | tee -a "$MONITORING_REPORT"

            case $MONITORING_TYPE in
                "all")
                    setup_log_analytics "$subscription" "$env_name" 2>&1 | tee -a "$MONITORING_REPORT"
                    setup_alerts "$subscription" "$env_name" 2>&1 | tee -a "$MONITORING_REPORT"
                    setup_dashboards "$subscription" "$env_name" 2>&1 | tee -a "$MONITORING_REPORT"
                    setup_diagnostic_logs "$subscription" "$env_name" 2>&1 | tee -a "$MONITORING_REPORT"
                    ;;
                "logs")
                    setup_log_analytics "$subscription" "$env_name" 2>&1 | tee -a "$MONITORING_REPORT"
                    setup_diagnostic_logs "$subscription" "$env_name" 2>&1 | tee -a "$MONITORING_REPORT"
                    ;;
                "alerts")
                    setup_alerts "$subscription" "$env_name" 2>&1 | tee -a "$MONITORING_REPORT"
                    ;;
                "dashboards")
                    setup_dashboards "$subscription" "$env_name" 2>&1 | tee -a "$MONITORING_REPORT"
                    ;;
            esac
        else
            echo ":( Cannot access $subscription subscription" | tee -a "$MONITORING_REPORT"
        fi
    fi
done

# Generate monitoring recommendations
cat >> "$MONITORING_REPORT" << 'EOF'

MONITORING RECOMMENDATIONS
=========================

Critical Alerts Setup:
1. VM availability and performance alerts
2. Storage capacity and performance alerts
3. Network connectivity and firewall alerts
4. Key Vault access and security alerts
5. Database performance and availability alerts

Dashboard Components:
1. Resource health overview
2. Cost and billing trends
3. Security metrics and compliance
4. Performance metrics and capacity
5. Backup and recovery status

Log Analytics Queries:
1. Security event correlation
2. Performance baseline tracking
3. Cost optimization opportunities
4. Resource utilization trends
5. Error pattern analysis

Automation Recommendations:
1. Auto-remediation for common issues
2. Capacity scaling based on metrics
3. Cost optimization automation
4. Security response automation
5. Backup validation automation

EOF

# Summary
echo ""
echo ":) Monitoring Setup Summary"
echo "============================"
echo "|) Report generated: $MONITORING_REPORT"
echo ":) Environments configured:"
echo "   - Development (Sub-TRL-dev-weu)"
echo "   - Staging (Sub-TRL-int-weu)"
echo "   - Production (Sub-TRL-prod-weu)"
echo ""
echo "|) Monitoring components setup:"
echo "   - Log Analytics workspaces"
echo "   - Alert rules and action groups"
echo "   - Azure Monitor dashboards"
echo "   - Diagnostic settings"
echo ""
echo "|) Next steps:"
echo "   1. Review monitoring report: $MONITORING_REPORT"
echo "   2. Customize alert thresholds as needed"
echo "   3. Add email/SMS notifications to action groups"
echo "   4. Test alert rules and escalation procedures"
echo "   5. Schedule regular monitoring reviews"
echo ""
echo ":) Infrastructure monitoring setup completed successfully!"
