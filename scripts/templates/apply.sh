#!/bin/bash
# Terraform Apply Script for TRL Hub and Spoke Infrastructure

set -e

echo "🚀 Applying Terraform configuration for TRL Hub and Spoke Infrastructure..."

# Set environment variables
export TF_VAR_subscription_id="${AZURE_SUBSCRIPTION_ID}"
export TF_VAR_tenant_id="${AZURE_TENANT_ID}"
export TF_VAR_client_id="${AZURE_CLIENT_ID}"
export TF_VAR_client_secret="${AZURE_CLIENT_SECRET}"

# Navigate to the environment directory
cd terraform/environments/prod

# Check if plan file is provided
PLAN_FILE=""
if [ $# -eq 1 ]; then
    PLAN_FILE=$1
    echo "📄 Using plan file: ${PLAN_FILE}"
else
    echo "⚠️  No plan file provided - will create and apply plan automatically"
    echo "🔍 Creating fresh plan..."

    # Generate timestamp for plan file
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    PLAN_FILE="tfplan_${TIMESTAMP}.out"

    # Create plan
    terraform plan \
      -out="${PLAN_FILE}" \
      -var-file="terraform.tfvars" \
      -lock=true \
      -lock-timeout=300s
fi

# Validate plan file exists
if [ ! -f "${PLAN_FILE}" ]; then
    echo "❌ Plan file ${PLAN_FILE} not found!"
    exit 1
fi

# Show plan summary before applying
echo ""
echo "📋 Plan Summary:"
terraform show -no-color "${PLAN_FILE}" | grep -E "Plan:|Changes to Outputs:"
echo ""

# Confirmation prompt
read -p "🤔 Do you want to apply these changes? (yes/no): " CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
    echo "❌ Apply cancelled by user"
    exit 1
fi

# Apply the plan
echo "⚡ Running terraform apply..."
terraform apply \
  -lock=true \
  -lock-timeout=300s \
  "${PLAN_FILE}"

# Check apply result
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Terraform apply completed successfully!"
    echo "🎯 Infrastructure deployment summary:"
    terraform output
    echo ""
    echo "📋 Next steps:"
    echo "   - Verify resources in Azure Portal"
    echo "   - Test connectivity through Azure Bastion"
    echo "   - Monitor Azure Firewall logs"
    echo "   - Review cost optimization opportunities"
else
    echo "❌ Terraform apply failed!"
    exit 1
fi

# Cleanup plan file
rm -f "${PLAN_FILE}"
echo "🧹 Cleaned up plan file: ${PLAN_FILE}"
