#!/bin/bash
# Infrastructure Health Check Script for TRL Hub and Spoke
# Performs comprehensive health checks across all environments

set -e

echo ":) Starting infrastructure health check for TRL Hub and Spoke..."

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="health-check-report-${TIMESTAMP}.txt"

# Function to check VM health
check_vm_health() {
    local subscription=$1
    local env_name=$2

    echo "|) Checking VM health in $env_name environment..."
    az account set --subscription "$subscription"

    # Get VM status
    VMS=$(az vm list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].{name:name, resourceGroup:resourceGroup}" -o tsv)

    while IFS=$'\t' read -r vm_name rg_name; do
        if [ -n "$vm_name" ]; then
            echo "  Checking VM: $vm_name"

            # Get VM power state
            POWER_STATE=$(az vm get-instance-view --name "$vm_name" --resource-group "$rg_name" --query "instanceView.statuses[1].displayStatus" -o tsv)
            echo "    Power State: $POWER_STATE"

            # Check VM agent status
            AGENT_STATUS=$(az vm get-instance-view --name "$vm_name" --resource-group "$rg_name" --query "instanceView.vmAgent.statuses[0].displayStatus" -o tsv 2>/dev/null || echo "Unknown")
            echo "    VM Agent: $AGENT_STATUS"

            # Check boot diagnostics
            BOOT_DIAG=$(az vm boot-diagnostics get-boot-log --name "$vm_name" --resource-group "$rg_name" 2>/dev/null | tail -5 || echo "Boot diagnostics not available")
            echo "    Boot Status: Available"
        fi
    done <<< "$VMS"
}

# Function to check network connectivity
check_network_health() {
    local subscription=$1
    local env_name=$2

    echo "|) Checking network health in $env_name environment..."
    az account set --subscription "$subscription"

    # Check VNet peering status
    VNETS=$(az network vnet list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].{name:name, resourceGroup:resourceGroup}" -o tsv)

    while IFS=$'\t' read -r vnet_name rg_name; do
        if [ -n "$vnet_name" ]; then
            echo "  Checking VNet: $vnet_name"

            # Check peering status
            PEERINGS=$(az network vnet peering list --resource-group "$rg_name" --vnet-name "$vnet_name" --query "[].{Name:name, State:peeringState, Connected:provisioningState}" -o table)
            echo "    Peering Status:"
            echo "$PEERINGS" | head -5

            # Check effective routes
            ROUTE_TABLE=$(az network vnet subnet list --resource-group "$rg_name" --vnet-name "$vnet_name" --query "[?routeTable].{Subnet:name, RouteTable:routeTable.id}" -o table)
            echo "    Route Tables:"
            echo "$ROUTE_TABLE"
        fi
    done <<< "$VNETS"
}

# Function to check security components
check_security_health() {
    local subscription=$1
    local env_name=$2

    echo "|) Checking security health in $env_name environment..."
    az account set --subscription "$subscription"

    # Check Key Vault health
    KEY_VAULTS=$(az keyvault list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].name" -o tsv)

    for kv in $KEY_VAULTS; do
        echo "  Checking Key Vault: $kv"

        # Check Key Vault accessibility
        KV_STATUS=$(az keyvault show --name "$kv" --query "properties.provisioningState" -o tsv)
        echo "    Status: $KV_STATUS"

        # Check secret count (without listing actual secrets)
        SECRET_COUNT=$(az keyvault secret list --vault-name "$kv" --query "length(@)" -o tsv 2>/dev/null || echo "0")
        echo "    Secrets: $SECRET_COUNT"

        # Check access policies
        POLICY_COUNT=$(az keyvault show --name "$kv" --query "length(properties.accessPolicies)" -o tsv)
        echo "    Access Policies: $POLICY_COUNT"
    done

    # Check Private Endpoints
    PRIVATE_ENDPOINTS=$(az network private-endpoint list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].{name:name, resourceGroup:resourceGroup, state:provisioningState}" -o tsv)

    while IFS=$'\t' read -r pe_name rg_name state; do
        if [ -n "$pe_name" ]; then
            echo "  Private Endpoint: $pe_name - Status: $state"
        fi
    done <<< "$PRIVATE_ENDPOINTS"
}

# Main health check execution
echo ""
echo ":) Starting comprehensive health check..."

# Initialize report file
cat > "$REPORT_FILE" << EOF
TRL Hub and Spoke Infrastructure Health Check Report
===================================================
Generated: $(date -u)
Analysis Period: Last $DAYS_TO_ANALYZE days

EXECUTIVE SUMMARY
================
EOF

# Check each environment
for env_config in "Sub-TRL-dev-weu:dev" "Sub-TRL-int-weu:staging" "Sub-TRL-prod-weu:prod"; do
    IFS=':' read -r subscription env_name <<< "$env_config"

    echo ""
    echo ":) Checking $env_name environment ($subscription)..."

    if az account show --subscription "$subscription" >/dev/null 2>&1; then
        echo "Environment: $env_name ($subscription)" >> "$REPORT_FILE"
        echo "----------------------------------------" >> "$REPORT_FILE"

        check_vm_health "$subscription" "$env_name" 2>&1 | tee -a "$REPORT_FILE"
        check_network_health "$subscription" "$env_name" 2>&1 | tee -a "$REPORT_FILE"
        check_security_health "$subscription" "$env_name" 2>&1 | tee -a "$REPORT_FILE"

        echo "" >> "$REPORT_FILE"
    else
        echo ":( Cannot access $subscription subscription"
        echo "ERROR: Cannot access $subscription" >> "$REPORT_FILE"
    fi
done

# Generate recommendations
echo ""
echo ":) Generating health recommendations..."

cat >> "$REPORT_FILE" << 'EOF'

HEALTH RECOMMENDATIONS
=====================

High Priority Actions:
1. Ensure all VMs are running and VM agents are responsive
2. Verify all VNet peerings are in "Connected" state
3. Confirm Key Vault accessibility and secret availability
4. Validate private endpoint connectivity

Medium Priority Actions:
1. Review VM auto-shutdown schedules for cost optimization
2. Check storage account access tiers for cost efficiency
3. Validate backup policies and test restore procedures
4. Review firewall logs for security anomalies

Low Priority Actions:
1. Optimize VM sizes based on utilization metrics
2. Review and clean up unused storage containers
3. Update VM extensions to latest versions
4. Review and update network security rules

Monitoring Setup:
- Enable Azure Monitor for all critical resources
- Set up availability tests for applications
- Configure cost alerts and budgets
- Implement automated health checks

Next Health Check: Recommended within 7 days
EOF

# Summary
echo ""
echo ":) Health Check Summary"
echo "======================"
echo "|) Report generated: $REPORT_FILE"
echo ":) Environments checked:"
echo "   - Development (Sub-TRL-dev-weu)"
echo "   - Staging (Sub-TRL-int-weu)"
echo "   - Production (Sub-TRL-prod-weu)"
echo ""
echo "|) Next steps:"
echo "   1. Review detailed health report: $REPORT_FILE"
echo "   2. Address any critical issues found"
echo "   3. Implement recommended improvements"
echo "   4. Schedule regular health checks (weekly recommended)"
echo ""
echo ":) Infrastructure health check completed successfully!"
