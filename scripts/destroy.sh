#!/bin/bash
# Terraform Destroy Script for TRL Hub and Spoke Infrastructure

set -e

echo ":( Destroying TRL Hub and Spoke Infrastructure..."
echo ":| WARNING: This will permanently delete all resources!"

# Set environment variables
export TF_VAR_subscription_id="${AZURE_SUBSCRIPTION_ID}"
export TF_VAR_tenant_id="${AZURE_TENANT_ID}"
export TF_VAR_client_id="${AZURE_CLIENT_ID}"
export TF_VAR_client_secret="${AZURE_CLIENT_SECRET}"

# Navigate to the environment directory
cd terraform/environments/prod

# Show current state
echo "|) Current infrastructure state:"
terraform show -no-color | head -20
echo "..."
echo ""

# Multiple confirmation prompts for safety
echo ":( DANGER ZONE :("
echo "This will destroy ALL infrastructure including:"
echo "   - Virtual Networks and Subnets"
echo "   - Azure Firewall and Bastion"
echo "   - Virtual Machines and Storage"
echo "   - Key Vault and all secrets"
echo "   - Private DNS zones"
echo "   - ALL DATA WILL BE LOST!"
echo ""

read -p "Type 'DESTROY' to confirm you want to proceed: " CONFIRM1
if [ "${CONFIRM1}" != "DESTROY" ]; then
    echo ":( Destroy cancelled - confirmation failed"
    exit 1
fi

read -p "Are you absolutely sure? Type 'YES' to continue: " CONFIRM2
if [ "${CONFIRM2}" != "YES" ]; then
    echo ":( Destroy cancelled - final confirmation failed"
    exit 1
fi

# Create destroy plan
echo ":) Creating destroy plan..."
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DESTROY_PLAN="destroy_plan_${TIMESTAMP}.out"

terraform plan \
  -destroy \
  -out="${DESTROY_PLAN}" \
  -var-file="terraform.tfvars" \
  -lock=true \
  -lock-timeout=300s

# Show destroy plan
echo ""
echo "|) Destroy Plan Summary:"
terraform show -no-color "${DESTROY_PLAN}" | grep -E "Plan:|Changes to Outputs:"
echo ""

# Final confirmation
read -p ":| Proceed with destruction? Type 'CONFIRM' to destroy: " FINAL_CONFIRM
if [ "${FINAL_CONFIRM}" != "CONFIRM" ]; then
    echo ":( Destroy cancelled - final safety check failed"
    rm -f "${DESTROY_PLAN}"
    exit 1
fi

# Execute destroy
echo ":( Executing terraform destroy..."
terraform apply \
  -lock=true \
  -lock-timeout=300s \
  "${DESTROY_PLAN}"

# Check destroy result
if [ $? -eq 0 ]; then
    echo ""
    echo ":) Infrastructure destroyed successfully!"
    echo ":) All resources have been removed"
    echo ":) No further costs will be incurred"
    echo ""
    echo "|) Post-destroy checklist:"
    echo "   - Verify resource groups are empty in Azure Portal"
    echo "   - Check for any orphaned resources"
    echo "   - Review final cost summary"
    echo "   - Clean up service principal if no longer needed"
else
    echo ":( Terraform destroy failed!"
    echo ":) Check for dependencies or locked resources"
    exit 1
fi

# Cleanup
rm -f "${DESTROY_PLAN}"
echo ":) Cleaned up destroy plan file"
