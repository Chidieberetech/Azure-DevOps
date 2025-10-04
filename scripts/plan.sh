#!/bin/bash
# Terraform Plan Script for TRL Hub and Spoke Infrastructure

set -e

echo "|) Creating Terraform execution plan for TRL Hub and Spoke Infrastructure..."

# Set environment variables
export TF_VAR_subscription_id="${AZURE_SUBSCRIPTION_ID}"
export TF_VAR_tenant_id="${AZURE_TENANT_ID}"
export TF_VAR_client_id="${AZURE_CLIENT_ID}"
export TF_VAR_client_secret="${AZURE_CLIENT_SECRET}"

# Navigate to the environment directory
cd terraform/environments/prod

# Generate timestamp for plan file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PLAN_FILE="tfplan_${TIMESTAMP}.out"

# Create Terraform plan
echo ":) Running terraform plan..."
terraform plan \
  -detailed-exitcode \
  -out="${PLAN_FILE}" \
  -var-file="terraform.tfvars" \
  -lock=true \
  -lock-timeout=300s

# Check plan exit code
PLAN_EXIT_CODE=$?

case $PLAN_EXIT_CODE in
  0)
    echo ":) No changes detected - infrastructure is up to date"
    ;;
  1)
    echo ":( Terraform plan failed with errors"
    exit 1
    ;;
  2)
    echo ":) Changes detected - plan created successfully"
    echo "|) Plan file: ${PLAN_FILE}"
    echo ""
    echo "|) Plan Summary:"
    terraform show -no-color "${PLAN_FILE}" | grep -E "Plan:|Changes to Outputs:"
    echo ""
    echo ":) Next steps:"
    echo "   - Review the plan carefully"
    echo "   - Run terraform apply ${PLAN_FILE} to apply changes"
    echo "   - Or run destroy script to tear down infrastructure"
    ;;
esac

exit $PLAN_EXIT_CODE
