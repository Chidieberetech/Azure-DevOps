#!/bin/bash
# Environment Cleanup Script for TRL Hub and Spoke Infrastructure
# Cleans up temporary resources, old backups, and optimizes environments

set -e

echo ":) Starting environment cleanup for TRL Hub and Spoke Infrastructure..."

# Configuration
CLEANUP_REPORT="cleanup-report-$(date +%Y%m%d-%H%M%S).txt"
DRY_RUN=false

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV   Environment to clean (dev/staging/prod/all)"
    echo "  -t, --type TYPE         Cleanup type (storage/snapshots/logs/unused/all)"
    echo "  -d, --dry-run          Show what would be cleaned without executing"
    echo "  -f, --force            Force cleanup without confirmation"
    echo "  -h, --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e dev -t all -d                  # Dry run cleanup for dev environment"
    echo "  $0 -e prod -t snapshots -f          # Force cleanup old snapshots in prod"
    echo "  $0 -e all -t unused                 # Clean unused resources in all environments"
}

# Parse command line arguments
ENVIRONMENT="all"
CLEANUP_TYPE="all"
FORCE_CLEANUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--type)
            CLEANUP_TYPE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE_CLEANUP=true
            shift
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

# Function to cleanup storage
cleanup_storage() {
    local subscription=$1
    local env_name=$2

    echo "|) Cleaning up storage in $env_name environment..."
    az account set --subscription "$subscription"

    # Find storage accounts
    STORAGE_ACCOUNTS=$(az storage account list --query "[?starts_with(name, 'trl') && contains(name, '$env_name')].{name:name, resourceGroup:resourceGroup}" -o tsv)

    while IFS=$'\t' read -r storage_name rg_name; do
        if [ -n "$storage_name" ]; then
            echo "  Processing storage account: $storage_name"

            # Get account key
            STORAGE_KEY=$(az storage account keys list --resource-group "$rg_name" --account-name "$storage_name" --query "[0].value" -o tsv)

            # Clean up old blobs (older than 30 days in non-prod)
            if [[ "$env_name" != "prod" ]]; then
                echo "    Checking for old blobs..."

                if [ "$DRY_RUN" = true ]; then
                    echo "    :| DRY RUN: Would delete blobs older than 30 days"
                else
                    # List containers
                    CONTAINERS=$(az storage container list --account-name "$storage_name" --account-key "$STORAGE_KEY" --query "[].name" -o tsv 2>/dev/null || echo "")

                    for container in $CONTAINERS; do
                        echo "      Cleaning container: $container"
                        az storage blob delete-batch \
                            --account-name "$storage_name" \
                            --account-key "$STORAGE_KEY" \
                            --source "$container" \
                            --if-older-than $(date -d "30 days ago" +%Y-%m-%d) 2>/dev/null || true
                    done
                fi
            fi

            # Clean up empty containers
            echo "    :) Storage cleanup completed for $storage_name"
        fi
    done <<< "$STORAGE_ACCOUNTS"
}

# Function to cleanup snapshots
cleanup_snapshots() {
    local subscription=$1
    local env_name=$2

    echo "|) Cleaning up old snapshots in $env_name environment..."
    az account set --subscription "$subscription"

    # Find old snapshots (older than 7 days for dev, 30 days for others)
    if [[ "$env_name" == "dev" ]]; then
        RETENTION_DAYS=7
    else
        RETENTION_DAYS=30
    fi

    OLD_SNAPSHOTS=$(az snapshot list --query "[?starts_with(name, 'trl-hubspoke-$env_name') && timeCreated < '$(date -d "$RETENTION_DAYS days ago" --iso-8601)'].{name:name, resourceGroup:resourceGroup, created:timeCreated}" -o tsv)

    while IFS=$'\t' read -r snapshot_name rg_name created_date; do
        if [ -n "$snapshot_name" ]; then
            echo "  Found old snapshot: $snapshot_name (created: $created_date)"

            if [ "$DRY_RUN" = true ]; then
                echo "    :| DRY RUN: Would delete snapshot $snapshot_name"
            else
                if [ "$FORCE_CLEANUP" = true ]; then
                    az snapshot delete --name "$snapshot_name" --resource-group "$rg_name" --yes
                    echo "    :) Deleted snapshot: $snapshot_name"
                else
                    read -p "    Delete snapshot $snapshot_name? (y/n): " confirm
                    if [[ "$confirm" == "y" ]]; then
                        az snapshot delete --name "$snapshot_name" --resource-group "$rg_name" --yes
                        echo "    :) Deleted snapshot: $snapshot_name"
                    fi
                fi
            fi
        fi
    done <<< "$OLD_SNAPSHOTS"
}

# Function to cleanup unused resources
cleanup_unused_resources() {
    local subscription=$1
    local env_name=$2

    echo "|) Cleaning up unused resources in $env_name environment..."
    az account set --subscription "$subscription"

    # Find unused NICs
    echo "  Checking for unused Network Interfaces..."
    UNUSED_NICS=$(az network nic list --query "[?starts_with(name, 'trl-hubspoke-$env_name') && virtualMachine == null].{name:name, resourceGroup:resourceGroup}" -o tsv)

    while IFS=$'\t' read -r nic_name rg_name; do
        if [ -n "$nic_name" ]; then
            echo "    Found unused NIC: $nic_name"
            if [ "$DRY_RUN" = true ]; then
                echo "      :| DRY RUN: Would delete unused NIC $nic_name"
            else
                if [ "$FORCE_CLEANUP" = true ]; then
                    az network nic delete --name "$nic_name" --resource-group "$rg_name" --yes
                    echo "      :) Deleted unused NIC: $nic_name"
                fi
            fi
        fi
    done <<< "$UNUSED_NICS"

    # Find unused disks
    echo "  Checking for unused Managed Disks..."
    UNUSED_DISKS=$(az disk list --query "[?starts_with(name, 'trl-hubspoke-$env_name') && managedBy == null].{name:name, resourceGroup:resourceGroup, sizeGb:diskSizeGb}" -o tsv)

    while IFS=$'\t' read -r disk_name rg_name disk_size; do
        if [ -n "$disk_name" ]; then
            echo "    Found unused disk: $disk_name ($disk_size GB)"
            if [ "$DRY_RUN" = true ]; then
                echo "      :| DRY RUN: Would delete unused disk $disk_name"
            else
                if [ "$FORCE_CLEANUP" = true ]; then
                    az disk delete --name "$disk_name" --resource-group "$rg_name" --yes
                    echo "      :) Deleted unused disk: $disk_name"
                fi
            fi
        fi
    done <<< "$UNUSED_DISKS"
}

# Function to cleanup logs
cleanup_logs() {
    local subscription=$1
    local env_name=$2

    echo "|) Cleaning up old logs in $env_name environment..."
    az account set --subscription "$subscription"

    # Find Log Analytics workspaces
    LOG_WORKSPACES=$(az monitor log-analytics workspace list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].{name:name, resourceGroup:resourceGroup}" -o tsv)

    while IFS=$'\t' read -r workspace_name rg_name; do
        if [ -n "$workspace_name" ]; then
            echo "  Checking workspace: $workspace_name"

            # Get workspace info
            RETENTION=$(az monitor log-analytics workspace show --workspace-name "$workspace_name" --resource-group "$rg_name" --query "retentionInDays" -o tsv)
            echo "    Current retention: $RETENTION days"

            if [[ "$env_name" == "dev" && "$RETENTION" -gt 30 ]]; then
                echo "    :| Recommendation: Reduce retention to 30 days for dev environment"
                if [ "$DRY_RUN" = false ] && [ "$FORCE_CLEANUP" = true ]; then
                    az monitor log-analytics workspace update \
                        --workspace-name "$workspace_name" \
                        --resource-group "$rg_name" \
                        --retention-time 30
                    echo "    :) Updated retention to 30 days"
                fi
            fi
        fi
    done <<< "$LOG_WORKSPACES"
}

# Main execution
echo ""
echo ":) Starting cleanup operation..."
echo "|) Environment: $ENVIRONMENT"
echo "|) Cleanup type: $CLEANUP_TYPE"
echo "|) Dry run: $DRY_RUN"

if [ "$DRY_RUN" = true ]; then
    echo ":| DRY RUN MODE - No changes will be made"
fi

# Initialize cleanup report
cat > "$CLEANUP_REPORT" << EOF
TRL Hub and Spoke Infrastructure Cleanup Report
===============================================
Generated: $(date -u)
Environment: $ENVIRONMENT
Cleanup Type: $CLEANUP_TYPE
Dry Run: $DRY_RUN

CLEANUP OPERATIONS
==================
EOF

# Execute cleanup for specified environments
for env_config in "Sub-TRL-dev-weu:dev" "Sub-TRL-int-weu:staging" "Sub-TRL-prod-weu:prod"; do
    IFS=':' read -r subscription env_name <<< "$env_config"

    if [[ "$ENVIRONMENT" == "all" || "$ENVIRONMENT" == "$env_name" ]]; then
        if az account show --subscription "$subscription" >/dev/null 2>&1; then
            echo "" | tee -a "$CLEANUP_REPORT"
            echo "Processing $env_name environment..." | tee -a "$CLEANUP_REPORT"

            case $CLEANUP_TYPE in
                "all")
                    cleanup_storage "$subscription" "$env_name" 2>&1 | tee -a "$CLEANUP_REPORT"
                    cleanup_snapshots "$subscription" "$env_name" 2>&1 | tee -a "$CLEANUP_REPORT"
                    cleanup_unused_resources "$subscription" "$env_name" 2>&1 | tee -a "$CLEANUP_REPORT"
                    cleanup_logs "$subscription" "$env_name" 2>&1 | tee -a "$CLEANUP_REPORT"
                    ;;
                "storage")
                    cleanup_storage "$subscription" "$env_name" 2>&1 | tee -a "$CLEANUP_REPORT"
                    ;;
                "snapshots")
                    cleanup_snapshots "$subscription" "$env_name" 2>&1 | tee -a "$CLEANUP_REPORT"
                    ;;
                "unused")
                    cleanup_unused_resources "$subscription" "$env_name" 2>&1 | tee -a "$CLEANUP_REPORT"
                    ;;
                "logs")
                    cleanup_logs "$subscription" "$env_name" 2>&1 | tee -a "$CLEANUP_REPORT"
                    ;;
            esac
        else
            echo ":( Cannot access $subscription subscription" | tee -a "$CLEANUP_REPORT"
        fi
    fi
done

# Generate summary
echo ""
echo ":) Environment Cleanup Summary"
echo "=============================="
echo "|) Cleanup report: $CLEANUP_REPORT"
echo ":) Environments processed: $ENVIRONMENT"
echo ":) Cleanup type: $CLEANUP_TYPE"
echo "|) Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "EXECUTION")"
echo ""
echo "|) Next steps:"
echo "   1. Review cleanup report for details"
echo "   2. Verify critical resources are not affected"
echo "   3. Monitor cost reduction after cleanup"
echo "   4. Schedule regular cleanup operations"
echo ""
echo ":) Environment cleanup completed successfully!"
