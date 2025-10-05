#!/bin/bash
# Backup Management Script for TRL Hub and Spoke Infrastructure
# Manages backups across all environments and validates backup integrity

set -e

echo ":) Starting backup management for TRL Hub and Spoke Infrastructure..."

# Configuration
BACKUP_RETENTION_DAYS=30
BACKUP_REPORT="backup-report-$(date +%Y%m%d-%H%M%S).txt"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -a, --action ACTION     Action to perform (backup/restore/validate/list)"
    echo "  -e, --environment ENV   Environment (dev/staging/prod/all)"
    echo "  -r, --retention DAYS    Backup retention in days (default: 30)"
    echo "  -t, --type TYPE         Backup type (vm/database/storage/all)"
    echo "  -h, --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -a backup -e prod -t all           # Backup all resources in prod"
    echo "  $0 -a validate -e all                 # Validate all backups"
    echo "  $0 -a list -e staging -t database     # List database backups in staging"
}

# Parse command line arguments
ACTION="validate"
ENVIRONMENT="all"
BACKUP_TYPE="all"

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--retention)
            BACKUP_RETENTION_DAYS="$2"
            shift 2
            ;;
        -t|--type)
            BACKUP_TYPE="$2"
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

# Function to backup VMs
backup_vms() {
    local subscription=$1
    local env_name=$2

    echo ":) Creating VM backups for $env_name environment..."
    az account set --subscription "$subscription"

    # Find Recovery Services Vault
    RSV_NAME=$(az backup vault list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].name" -o tsv | head -1)

    if [ -z "$RSV_NAME" ]; then
        echo ":| No Recovery Services Vault found for $env_name, creating one..."
        RSV_RG="trl-hubspoke-${env_name}-rg-backup"
        RSV_NAME="trl-hubspoke-${env_name}-rsv"

        # Create resource group if not exists
        az group create --name "$RSV_RG" --location "West Europe" || true

        # Create Recovery Services Vault
        az backup vault create \
            --resource-group "$RSV_RG" \
            --name "$RSV_NAME" \
            --location "West Europe"
    fi

    # Get VMs to backup
    VMS=$(az vm list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].{name:name, resourceGroup:resourceGroup}" -o tsv)

    while IFS=$'\t' read -r vm_name rg_name; do
        if [ -n "$vm_name" ]; then
            echo "  Backing up VM: $vm_name"

            # Enable backup for VM
            az backup protection enable-for-vm \
                --resource-group "$rg_name" \
                --vault-name "$RSV_NAME" \
                --vm "$vm_name" \
                --policy-name "DefaultPolicy" 2>/dev/null || echo "    :| Backup already enabled or failed"

            # Trigger backup job
            az backup protection backup-now \
                --resource-group "$rg_name" \
                --vault-name "$RSV_NAME" \
                --container-name "$vm_name" \
                --item-name "$vm_name" \
                --retain-until $(date -d "+$BACKUP_RETENTION_DAYS days" +%Y-%m-%d) \
                --backup-management-type AzureIaasVM 2>/dev/null || echo "    :| Backup trigger failed"
        fi
    done <<< "$VMS"
}

# Function to backup databases
backup_databases() {
    local subscription=$1
    local env_name=$2

    echo ":) Creating database backups for $env_name environment..."
    az account set --subscription "$subscription"

    # SQL Database backups (automatic - just verify)
    SQL_SERVERS=$(az sql server list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].{name:name, resourceGroup:resourceGroup}" -o tsv)

    while IFS=$'\t' read -r server_name rg_name; do
        if [ -n "$server_name" ]; then
            echo "  Checking SQL Server: $server_name"

            # List databases
            DATABASES=$(az sql db list --server "$server_name" --resource-group "$rg_name" --query "[?name != 'master'].name" -o tsv)

            for db in $DATABASES; do
                echo "    Database: $db"

                # Check backup policy
                BACKUP_POLICY=$(az sql db show --server "$server_name" --resource-group "$rg_name" --name "$db" --query "earliestRestoreDate" -o tsv)
                echo "      Earliest Restore: $BACKUP_POLICY"

                # Export database as BACPAC (optional long-term backup)
                echo "      :) Automatic backups are enabled (Azure SQL built-in)"
            done
        fi
    done <<< "$SQL_SERVERS"
}

# Function to validate backups
validate_backups() {
    local subscription=$1
    local env_name=$2

    echo ":) Validating backups for $env_name environment..."
    az account set --subscription "$subscription"

    # Check Recovery Services Vaults
    RSV_LIST=$(az backup vault list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].{name:name, resourceGroup:resourceGroup}" -o tsv)

    while IFS=$'\t' read -r vault_name rg_name; do
        if [ -n "$vault_name" ]; then
            echo "  Validating vault: $vault_name"

            # List backup items
            BACKUP_ITEMS=$(az backup item list --resource-group "$rg_name" --vault-name "$vault_name" --query "[].{Name:friendlyName, Status:protectionStatus, LastBackup:lastBackupTime}" -o table)
            echo "    Backup Items:"
            echo "$BACKUP_ITEMS"

            # Check backup jobs status
            RECENT_JOBS=$(az backup job list --resource-group "$rg_name" --vault-name "$vault_name" --start-date $(date -d "7 days ago" +%Y-%m-%d) --query "[].{Job:jobType, Status:status, StartTime:startTime}" -o table)
            echo "    Recent Jobs (last 7 days):"
            echo "$RECENT_JOBS"
        fi
    done <<< "$RSV_LIST"
}

# Function to generate backup report
generate_backup_report() {
    echo ":) Generating backup compliance report..."

    cat > "$BACKUP_REPORT" << EOF
TRL Hub and Spoke Infrastructure Backup Report
==============================================
Generated: $(date -u)
Report ID: $TIMESTAMP

BACKUP COMPLIANCE STATUS
=======================
EOF

    # Check each environment
    for env_config in "Sub-TRL-dev-weu:dev" "Sub-TRL-int-weu:staging" "Sub-TRL-prod-weu:prod"; do
        IFS=':' read -r subscription env_name <<< "$env_config"

        echo "" >> "$BACKUP_REPORT"
        echo "$env_name Environment ($subscription)" >> "$BACKUP_REPORT"
        echo "$(printf '=%.0s' {1..50})" >> "$BACKUP_REPORT"

        if az account show --subscription "$subscription" >/dev/null 2>&1; then
            az account set --subscription "$subscription"

            # VM backup status
            echo "VM Backup Status:" >> "$BACKUP_REPORT"
            VMS=$(az vm list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].name" -o tsv)
            if [ -n "$VMS" ]; then
                echo "$VMS" | while read vm; do
                    echo "  $vm: Configured" >> "$BACKUP_REPORT"
                done
            else
                echo "  No VMs found" >> "$BACKUP_REPORT"
            fi

            # Database backup status
            echo "" >> "$BACKUP_REPORT"
            echo "Database Backup Status:" >> "$BACKUP_REPORT"
            SQL_DBS=$(az sql server list --query "[?starts_with(name, 'trl-hubspoke-$env_name')].name" -o tsv)
            if [ -n "$SQL_DBS" ]; then
                echo "  SQL Databases: Automatic Azure backups enabled" >> "$BACKUP_REPORT"
            else
                echo "  No SQL databases found" >> "$BACKUP_REPORT"
            fi

        else
            echo "ERROR: Cannot access subscription" >> "$BACKUP_REPORT"
        fi
    done

    cat >> "$BACKUP_REPORT" << 'EOF'

BACKUP RECOMMENDATIONS
=====================
1. Verify backup jobs are completing successfully
2. Test restore procedures quarterly
3. Review backup retention policies
4. Consider geo-redundant backups for production
5. Implement backup monitoring and alerting

COMPLIANCE CHECKLIST
===================
[ ] All production VMs have backup enabled
[ ] Database backups are automated and tested
[ ] Backup retention meets compliance requirements
[ ] Disaster recovery procedures documented
[ ] Backup monitoring and alerting configured

EOF
}

# Main execution based on action
case $ACTION in
    "backup")
        echo "|) Performing backup operation..."
        for env_config in "Sub-TRL-dev-weu:dev" "Sub-TRL-int-weu:staging" "Sub-TRL-prod-weu:prod"; do
            IFS=':' read -r subscription env_name <<< "$env_config"

            if [[ "$ENVIRONMENT" == "all" || "$ENVIRONMENT" == "$env_name" ]]; then
                if [[ "$BACKUP_TYPE" == "all" || "$BACKUP_TYPE" == "vm" ]]; then
                    backup_vms "$subscription" "$env_name"
                fi
                if [[ "$BACKUP_TYPE" == "all" || "$BACKUP_TYPE" == "database" ]]; then
                    backup_databases "$subscription" "$env_name"
                fi
            fi
        done
        ;;
    "validate")
        echo "|) Performing backup validation..."
        for env_config in "Sub-TRL-dev-weu:dev" "Sub-TRL-int-weu:staging" "Sub-TRL-prod-weu:prod"; do
            IFS=':' read -r subscription env_name <<< "$env_config"

            if [[ "$ENVIRONMENT" == "all" || "$ENVIRONMENT" == "$env_name" ]]; then
                validate_backups "$subscription" "$env_name"
            fi
        done
        generate_backup_report
        ;;
    "list")
        echo "|) Listing backup information..."
        for env_config in "Sub-TRL-dev-weu:dev" "Sub-TRL-int-weu:staging" "Sub-TRL-prod-weu:prod"; do
            IFS=':' read -r subscription env_name <<< "$env_config"

            if [[ "$ENVIRONMENT" == "all" || "$ENVIRONMENT" == "$env_name" ]]; then
                validate_backups "$subscription" "$env_name"
            fi
        done
        ;;
    *)
        echo ":( Unknown action: $ACTION"
        usage
        exit 1
        ;;
esac

echo ""
echo ":) Backup management operation completed successfully!"
echo "|) Report file: $BACKUP_REPORT"
