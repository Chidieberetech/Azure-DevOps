#!/bin/bash
# Terraform Init Script for TRL Hub and Spoke Infrastructure

set -e

echo ":) Initializing Terraform for TRL Hub and Spoke Infrastructure..."

# Set environment variables
export TF_VAR_subscription_id="${AZURE_SUBSCRIPTION_ID}"
export TF_VAR_tenant_id="${AZURE_TENANT_ID}"
export TF_VAR_client_id="${AZURE_CLIENT_ID}"
export TF_VAR_client_secret="${AZURE_CLIENT_SECRET}"

# Navigate to the environment directory
cd terraform/environments/prod

# Initialize Terraform
echo "|) Running terraform init..."
terraform init \
  -backend-config="subscription_id=${AZURE_SUBSCRIPTION_ID}" \
  -backend-config="tenant_id=${AZURE_TENANT_ID}" \
  -backend-config="client_id=${AZURE_CLIENT_ID}" \
  -backend-config="client_secret=${AZURE_CLIENT_SECRET}"

# Validate configuration
echo ":) Validating Terraform configuration..."
terraform validate

echo ":) Terraform initialization completed successfully!"
echo "|) Next steps:"
echo "   - Run terraform plan to review changes"
echo "   - Run terraform apply to deploy infrastructure"
