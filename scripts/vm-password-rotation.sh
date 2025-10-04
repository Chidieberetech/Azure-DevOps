#!/bin/bash
# VM Password Rotation Script for TRL Hub and Spoke Infrastructure
# Automatically rotates VM passwords and updates Key Vault secrets

set -e

echo ":) Starting VM password rotation for TRL Hub and Spoke Infrastructure..."

# Configuration
KEY_VAULT_NAME=""
RESOURCE_GROUP_HUB=""
SUBSCRIPTION_ID=""

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -k, --keyvault NAME     Key Vault name (required)"
    echo "  -r, --resource-group    Hub resource group name (required)"
    echo "  -s, --subscription      Azure subscription ID (required)"
    echo "  -e, --environment       Environment (dev/staging/prod) - optional, rotates all if not specified"
    echo "  -f, --force            Force rotation without confirmation prompts"
    echo "  -h, --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -k trl-hubspoke-prod-kv-12345678 -r trl-hubspoke-prod-rg-hub -s 12345678-1234-1234-1234-123456789012"
    echo "  $0 -k trl-hubspoke-prod-kv-12345678 -r trl-hubspoke-prod-rg-hub -s 12345678-1234-1234-1234-123456789012 -e prod"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--keyvault)
            KEY_VAULT_NAME="$2"
            shift 2
            ;;
        -r|--resource-group)
            RESOURCE_GROUP_HUB="$2"
            shift 2
            ;;
        -s|--subscription)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -f|--force)
            FORCE_ROTATION=true
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

# Validate required parameters
if [ -z "$KEY_VAULT_NAME" ] || [ -z "$RESOURCE_GROUP_HUB" ] || [ -z "$SUBSCRIPTION_ID" ]; then
    echo ":( Error: Missing required parameters"
    usage
    exit 1
fi

# Set Azure subscription
echo ":) Setting Azure subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

# Verify Key Vault access
echo ":) Verifying Key Vault access..."
if ! az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP_HUB" >/dev/null 2>&1; then
    echo ":( Error: Cannot access Key Vault $KEY_VAULT_NAME"
    exit 1
fi

# Function to generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-16
}

# Function to rotate VM password
rotate_vm_password() {
    local vm_name=$1
    local resource_group=$2
    local environment=$3

    echo "|) Rotating password for VM: $vm_name"

    # Generate new password
    NEW_PASSWORD=$(generate_password)

    # Store new password in Key Vault
    SECRET_NAME="vm-admin-password-${environment}"
    echo ":) Storing new password in Key Vault..."
    az keyvault secret set \
        --vault-name "$KEY_VAULT_NAME" \
        --name "$SECRET_NAME" \
        --value "$NEW_PASSWORD" \
        --tags "LastRotated=$(date -u +%Y-%m-%dT%H:%M:%SZ)" "Environment=$environment" \
        >/dev/null

    # Update VM password
    echo ":) Updating VM password..."
    az vm user update \
        --resource-group "$resource_group" \
        --name "$vm_name" \
        --username "azureadmin" \
        --password "$NEW_PASSWORD"

    if [ $? -eq 0 ]; then
        echo ":) Password rotation completed for $vm_name"

        # Store backup of previous password (optional)
        BACKUP_SECRET_NAME="vm-admin-password-${environment}-backup"
        az keyvault secret set \
            --vault-name "$KEY_VAULT_NAME" \
            --name "$BACKUP_SECRET_NAME" \
            --value "$NEW_PASSWORD" \
            --tags "BackupDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)" "Environment=$environment" \
            >/dev/null

    else
        echo ":( Failed to update password for $vm_name"
        return 1
    fi
}

# Function to get VMs for environment
get_vms_for_environment() {
    local env=$1
    local rg_pattern="trl-hubspoke-${env}-rg-spoke"

    echo ":) Finding VMs in environment: $env"

    # Get all resource groups matching the pattern
    RESOURCE_GROUPS=$(az group list --query "[?starts_with(name, '$rg_pattern')].name" -o tsv)

    for rg in $RESOURCE_GROUPS; do
        echo "  Checking resource group: $rg"
        VMS=$(az vm list --resource-group "$rg" --query "[].name" -o tsv)

        for vm in $VMS; do
            echo "  Found VM: $vm in $rg"
            VM_LIST+=("$vm:$rg:$env")
        done
    done
}

# Confirmation prompt
if [ "$FORCE_ROTATION" != true ]; then
    echo ""
    echo ":| VM Password Rotation Warning"
    echo "==============================="
    echo ""
    echo "This script will:"
    echo "  - Generate new passwords for all VMs"
    echo "  - Update passwords in Azure Key Vault"
    echo "  - Apply new passwords to virtual machines"
    echo "  - Create backup copies of passwords"
    echo ""
    echo "Target Key Vault: $KEY_VAULT_NAME"
    echo "Target Subscription: $SUBSCRIPTION_ID"

    if [ -n "$ENVIRONMENT" ]; then
        echo "Target Environment: $ENVIRONMENT"
    else
        echo "Target Environments: ALL (dev, staging, prod)"
    fi

    echo ""
    read -p ":| Do you want to proceed with password rotation? (yes/no): " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo ":( Password rotation cancelled by user"
        exit 0
    fi
fi

# Main rotation logic
echo ""
echo ":) Starting password rotation process..."

# Determine environments to process
if [ -n "$ENVIRONMENT" ]; then
    ENVIRONMENTS=($ENVIRONMENT)
else
    ENVIRONMENTS=(dev staging prod)
fi

# Initialize VM list
VM_LIST=()

# Collect VMs from specified environments
for env in "${ENVIRONMENTS[@]}"; do
    get_vms_for_environment "$env"
done

# Check if any VMs were found
if [ ${#VM_LIST[@]} -eq 0 ]; then
    echo ":| No VMs found for rotation"
    exit 0
fi

echo ""
echo "|) Found ${#VM_LIST[@]} VM(s) for password rotation:"
for vm_info in "${VM_LIST[@]}"; do
    IFS=':' read -r vm_name rg env <<< "$vm_info"
    echo "  - $vm_name ($env environment)"
done

# Perform password rotation
echo ""
echo ":) Beginning password rotation..."
SUCCESS_COUNT=0
FAILURE_COUNT=0

for vm_info in "${VM_LIST[@]}"; do
    IFS=':' read -r vm_name rg env <<< "$vm_info"

    echo ""
    echo "Processing: $vm_name"

    if rotate_vm_password "$vm_name" "$rg" "$env"; then
        ((SUCCESS_COUNT++))
    else
        ((FAILURE_COUNT++))
        echo ":( Failed to rotate password for $vm_name"
    fi
done

# Summary report
echo ""
echo "======================="
echo "|) Password Rotation Summary"
echo "======================="
echo ":) Successfully rotated: $SUCCESS_COUNT VM(s)"
if [ $FAILURE_COUNT -gt 0 ]; then
    echo ":( Failed rotations: $FAILURE_COUNT VM(s)"
fi
echo ""

if [ $FAILURE_COUNT -eq 0 ]; then
    echo ":) All VM passwords rotated successfully!"
    echo ""
    echo "|) Post-rotation steps:"
    echo "  1. Test VM connectivity through Azure Bastion"
    echo "  2. Update any applications using old credentials"
    echo "  3. Verify Key Vault secret versions"
    echo "  4. Schedule next rotation (recommended: 90 days)"
    echo ""
    echo ":) Password rotation completed successfully!"
    exit 0
else
    echo ":( Some password rotations failed"
    echo "|) Please check the errors above and retry failed VMs"
    exit 1
fi
