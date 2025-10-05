#!/bin/bash
# Cost Analysis Script for TRL Hub and Spoke Infrastructure
# Analyzes Azure costs across all environments and provides optimization recommendations

set -e

echo ":) Starting cost analysis for TRL Hub and Spoke Infrastructure..."

# Configuration
DAYS_TO_ANALYZE=30
OUTPUT_FILE="cost-analysis-$(date +%Y%m%d-%H%M%S).json"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --days DAYS         Number of days to analyze (default: 30)"
    echo "  -o, --output FILE       Output file name (default: auto-generated)"
    echo "  -f, --format FORMAT     Output format (json/table/csv) default: json"
    echo "  -h, --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -d 7 -f table                    # Last 7 days in table format"
    echo "  $0 -d 90 -o quarterly-costs.json   # Last 90 days to specific file"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--days)
            DAYS_TO_ANALYZE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
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

# Calculate date range
END_DATE=$(date +%Y-%m-%d)
START_DATE=$(date -d "$DAYS_TO_ANALYZE days ago" +%Y-%m-%d)

echo "|) Analyzing costs from $START_DATE to $END_DATE"

# Function to analyze subscription costs
analyze_subscription_costs() {
    local subscription_name=$1
    local env_name=$2

    echo ":) Analyzing costs for $subscription_name ($env_name)..."

    # Set subscription context
    az account set --subscription "$subscription_name"

    # Get cost data
    az consumption usage list \
        --start-date "$START_DATE" \
        --end-date "$END_DATE" \
        --query "value[?contains(instanceName, 'trl-hubspoke')]" \
        > "${env_name}_costs_raw.json"

    # Get billing data
    az consumption budget list --query "value[].{Name:name, Amount:amount, CurrentSpend:currentSpend.amount, Status:status}" -o table

    # Get resource group costs
    echo "|) Resource group costs for $env_name:"
    az consumption usage list \
        --start-date "$START_DATE" \
        --end-date "$END_DATE" \
        --query "value[?contains(instanceName, 'trl-hubspoke')].{Resource:instanceName, Cost:pretaxCost, Currency:currency, Date:usageStart}" \
        -o table | head -20
}

# Analyze all environments
echo ""
echo ":) Analyzing costs across all TRL subscriptions..."

# Development Environment
if az account show --subscription "Sub-TRL-dev-weu" >/dev/null 2>&1; then
    analyze_subscription_costs "Sub-TRL-dev-weu" "dev"
else
    echo ":( Cannot access Sub-TRL-dev-weu subscription"
fi

# Staging Environment
if az account show --subscription "Sub-TRL-int-weu" >/dev/null 2>&1; then
    analyze_subscription_costs "Sub-TRL-int-weu" "staging"
else
    echo ":( Cannot access Sub-TRL-int-weu subscription"
fi

# Production Environment
if az account show --subscription "Sub-TRL-prod-weu" >/dev/null 2>&1; then
    analyze_subscription_costs "Sub-TRL-prod-weu" "prod"
else
    echo ":( Cannot access Sub-TRL-prod-weu subscription"
fi

# Generate cost optimization recommendations
echo ""
echo ":) Generating cost optimization recommendations..."

cat > cost-optimization-recommendations.md << 'EOF'
# Cost Optimization Recommendations
## TRL Hub and Spoke Infrastructure

### Immediate Actions:
1. **VM Auto-Shutdown**: Ensure all dev/staging VMs have auto-shutdown enabled
2. **Storage Tiering**: Move infrequently accessed data to cool storage
3. **Right-sizing**: Analyze VM utilization and downsize underutilized instances
4. **Reserved Instances**: Consider 1-year reserved instances for production VMs

### Free Tier Monitoring:
- **VM Hours**: Monitor usage against 750 hours/month limit per subscription
- **Storage**: Track blob storage usage against 5GB free limit
- **Database**: Monitor SQL DTU usage against 31 DTU days free
- **Networking**: Track outbound data transfer against 15GB free limit

### Cost Alerts Setup:
- Set budget alerts at 50%, 80%, and 100% of expected monthly costs
- Configure anomaly detection for unusual spending patterns
- Enable cost management recommendations in Azure Portal

### Environment-Specific Recommendations:

#### Development:
- Use B-series burstable VMs for variable workloads
- Enable auto-shutdown at 19:00 UTC daily
- Use Standard LRS storage for non-critical data
- Consider spot instances for non-production testing

#### Staging:
- Mirror production configuration but with smaller VM sizes
- Use staging slots for App Services to reduce costs
- Implement data lifecycle policies for temporary test data

#### Production:
- Use reserved instances for predictable workloads
- Consider Azure Hybrid Benefit for Windows licensing
- Implement geo-redundant storage only for critical data
- Use Azure Advisor recommendations for optimization
EOF

echo "|) Cost optimization recommendations saved to cost-optimization-recommendations.md"

# Generate summary report
echo ""
echo ":) Cost Analysis Summary"
echo "========================"
echo "|) Analysis period: $START_DATE to $END_DATE"
echo "|) Subscriptions analyzed:"
echo "   - Sub-TRL-dev-weu (Development)"
echo "   - Sub-TRL-int-weu (Staging)"
echo "   - Sub-TRL-prod-weu (Production)"
echo ""
echo ":) Cost data files generated:"
echo "   - dev_costs_raw.json"
echo "   - staging_costs_raw.json"
echo "   - prod_costs_raw.json"
echo "   - cost-optimization-recommendations.md"
echo ""
echo "|) Next steps:"
echo "   1. Review cost data files for detailed breakdown"
echo "   2. Implement optimization recommendations"
echo "   3. Set up cost alerts and budgets"
echo "   4. Schedule regular cost reviews"

echo ""
echo ":) Cost analysis completed successfully!"
