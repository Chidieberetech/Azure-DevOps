# Pipeline Deployment Guide

This guide provides comprehensive instructions for deploying Azure infrastructure using the Azure DevOps pipelines in this project.

## Table of Contents

- [Overview](#overview)
- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Deployment Workflows](#deployment-workflows)
- [Hub Workspace Deployment](#hub-workspace-deployment)
- [Spoke Workspace Deployment](#spoke-workspace-deployment)
- [Management Workspace Deployment](#management-workspace-deployment)
- [Environment Promotion](#environment-promotion)
- [Rollback Procedures](#rollback-procedures)
- [Monitoring Deployments](#monitoring-deployments)
- [Common Deployment Scenarios](#common-deployment-scenarios)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

This project uses Azure DevOps pipelines to deploy infrastructure following Infrastructure as Code (IaC) principles with Terraform.

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure DevOps Pipeline                   │
│                                                             │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐  │
│  │ Validate │ → │   Plan   │ → │ Approval │ → │  Apply   │  │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                      Azure Subscription                     │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                    Hub Virtual Network                 │ │
│  │  ┌──────────┐  ┌─────────┐  ┌──────────┐               │ │
│  │  │ Firewall │  │ Bastion │  │ Gateway  │               │ │
│  │  └──────────┘  └─────────┘  └──────────┘               │ │
│  └────────────────────────────────────────────────────────┘ │
│           │                │                │               │
│  ┌────────┴────┐  ┌────────┴────┐  ┌────────┴────┐          │
│  │ Spoke Alpha │  │ Spoke Beta  │  │Spoke Gamma  │          │
│  │    (Dev)    │  │    (Int)    │  │   (Prod)    │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Management Workspace                      │ │
│  │  ┌──────────────┐  ┌────────────┐  ┌──────────────┐    │ │
│  │  │Log Analytics │  │  Storage   │  │  Key Vault   │    │ │
│  │  └──────────────┘  └────────────┘  └──────────────┘    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Pipeline Stages

All pipelines follow this structure:

1. **Validate**: Syntax and configuration validation
2. **Plan**: Generate and review execution plan
3. **Approval**: Manual approval gate (production only)
4. **Apply**: Execute the deployment

## Pre-Deployment Checklist

### Before First Deployment

Complete these prerequisites:

#### 1. Azure Resources

- [ ] **Backend Storage Account** created
  ```bash
  az group create --name rg-terraform-state-prod --location westeurope
  az storage account create \
    --name sttfstateprodweu<random> \
    --resource-group rg-terraform-state-prod \
    --location westeurope \
    --sku Standard_LRS
  az storage container create --name tfstate \
    --account-name sttfstateprodweu<random>
  ```

- [ ] **Service Principal** created with permissions
  ```bash
  az ad sp create-for-rbac \
    --name sp-terraform-prod \
    --role Contributor \
    --scopes /subscriptions/<subscription-id>
  ```

- [ ] **Subscription access** verified
  ```bash
  az account show
  az account set --subscription <subscription-id>
  ```

#### 2. Azure DevOps Configuration

- [ ] **Project** created in Azure DevOps
- [ ] **Repository** imported or created
- [ ] **Service Connection** configured (see [PIPELINE-SETUP-GUIDE.md](PIPELINE-SETUP-GUIDE.md))
- [ ] **Variable Groups** created with all required variables (see [PIPELINE-VARIABLES-GUIDE.md](PIPELINE-VARIABLES-GUIDE.md))
- [ ] **Pipelines** created from YAML files
- [ ] **Environments** configured with approval gates
- [ ] **Agent pool** configured (Microsoft-hosted or self-hosted)

#### 3. Variable Groups Configured

Verify these variable groups exist and are populated:

- [ ] `terraform-backend-<env>`
- [ ] `azure-credentials-<env>`
- [ ] `terraform-vars-hub-<env>`
- [ ] `terraform-vars-spoke-<env>` (if deploying spokes separately)
- [ ] `terraform-vars-mgmt-<env>` (if deploying management separately)

#### 4. Permissions Verified

- [ ] Service principal has **Contributor** role on subscription
- [ ] Service principal has **Storage Blob Data Contributor** on backend storage
- [ ] Pipeline has access to all variable groups
- [ ] Appropriate users configured as approvers for production

### Before Each Deployment

- [ ] Review changes in source control
- [ ] Check for breaking changes in Terraform provider
- [ ] Verify variable values are correct for target environment
- [ ] Ensure no conflicting deployments are running
- [ ] Notify stakeholders of deployment window
- [ ] Have rollback plan ready

## Deployment Workflows

### Development Environment Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Feature Branch                                           │
│    Developer creates feature/xxx branch                     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Pull Request                                             │
│    PR triggers Plan pipeline (no apply)                     │
│    Terraform plan runs, results commented on PR             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Code Review                                              │
│    Team reviews code and plan output                        │
│    Approves and merges to main                              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Automatic Deployment                                     │
│    Main branch trigger runs full pipeline                   │
│    Validate → Plan → Apply (automatic for dev)              │
└─────────────────────────────────────────────────────────────┘
```

### Production Environment Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Tested in Dev/Int                                        │
│    Changes deployed and tested in lower environments        │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Production Deployment PR                                 │
│    Create PR to production branch                           │
│    Plan runs automatically                                  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Review and Approval                                      │
│    Infrastructure team reviews plan                         │
│    Security team reviews changes                            │
│    Management approves PR                                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Merge and Deploy                                         │
│    PR merged to production branch                           │
│    Pipeline runs: Validate → Plan                           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Manual Approval Gate                                     │
│    Designated approvers review and approve                  │
│    SLA: Respond within 24 hours                             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Apply Stage                                              │
│    Terraform applies changes                                │
│    Monitoring and validation                                │
└─────────────────────────────────────────────────────────────┘
```

## Hub Workspace Deployment

The Hub workspace deploys the central hub network with shared services.

### Hub Components

- **Hub Virtual Network**: Central network (10.0.0.0/16)
- **Azure Firewall**: Network security (optional)
- **Azure Bastion**: Secure VM access (optional)
- **VPN Gateway**: Site-to-site connectivity (optional)
- **Private DNS Zones**: Name resolution for private endpoints
- **Shared Services Subnet**: Shared infrastructure
- **VNet Peering**: Connections to spoke networks

### Deployment Steps

#### 1. Navigate to Pipeline

1. Go to **Pipelines** → **Pipelines**
2. Select **Hub-Production** (or appropriate environment)
3. Click **Run pipeline**

#### 2. Configure Run

1. Select **Branch**: `main` (or environment branch)
2. Review **Variables**:
   - `environment`: Ensure correct value (dev/int/prod)
   - `location`: Verify Azure region
   - `spoke_count`: Number of spokes (0-3)
3. Click **Run**

#### 3. Monitor Validation Stage

Watch the **Validate** stage:

```
Terraform Init
  - Initializing backend
  - Downloading providers (azurerm 4.51.0, random 3.7.2)
  - Backend configured successfully

Terraform Validate
  - Success! The configuration is valid
```

**If validation fails**: Review error messages and fix configuration before proceeding.

#### 4. Review Plan Stage

The **Plan** stage generates an execution plan:

```
Terraform Plan
  Plan: 45 to add, 0 to change, 0 to destroy
  
  Resources to be created:
    + azurerm_resource_group.hub
    + azurerm_virtual_network.hub
    + azurerm_subnet.firewall
    + azurerm_subnet.bastion
    + azurerm_public_ip.bastion
    + azurerm_bastion_host.main
    ...
```

**Review carefully**:
-  Expected resources being created
-  No unexpected deletions
-  Resource names follow naming conventions
-  Correct resource groups and locations

The plan is saved as an artifact for the Apply stage.

#### 5. Approval Gate (Production Only)

For production environments:

1. **Approvers notified** via email
2. **Review plan output** from previous stage
3. **Verify**:
   - Change window is appropriate
   - Stakeholders notified
   - Rollback plan ready
4. **Approve or Reject**:
   - Navigate to pipeline run
   - Click **Review** on pending approval
   - Add comment and approve/reject

**Approval SLA**: 24 hours (configurable)

#### 6. Apply Stage

After approval, the **Apply** stage executes:

```
Terraform Apply
  azurerm_resource_group.hub: Creating...
  azurerm_resource_group.hub: Creation complete after 2s
  azurerm_virtual_network.hub: Creating...
  azurerm_virtual_network.hub: Creation complete after 8s
  ...
  
  Apply complete! Resources: 45 added, 0 changed, 0 destroyed
```

**Monitoring**:
- Watch for errors in pipeline logs
- Check Azure Portal for resource creation
- Verify resources in correct resource groups

#### 7. Post-Deployment Validation

After successful deployment:

1. **Verify in Azure Portal**:
   ```bash
   # List resource groups
   az group list --output table --query "[?contains(name, 'trl-prd-hub')]"
   
   # List resources in hub
   az resource list --resource-group rg-trl-prd-hub-001 --output table
   
   # Verify virtual network
   az network vnet show --name vnet-trl-prd-hub-001 \
     --resource-group rg-trl-prd-hub-001
   ```

2. **Test connectivity**:
   - Verify VNet peering status
   - Test Bastion connectivity (if enabled)
   - Validate private DNS zones

3. **Review monitoring**:
   - Check Log Analytics workspace
   - Verify diagnostic settings
   - Review initial metrics

### Hub Deployment Variables

Key variables for hub deployment (from `terraform-vars-hub-<env>`):

| Variable                 | Dev     | Int     | Prod   |
|--------------------------|---------|---------|--------|
| `environment`            | `dev`   | `int`   | `prod` |
| `spoke_count`            | `1`     | `2`     | `3`    |
| `enable_firewall`        | `false` | `true`  | `true` |
| `enable_bastion`         | `true`  | `true`  | `true` |
| `enable_ddos_protection` | `false` | `false` | `true` |
| `enable_vpn_gateway`     | `false` | `false` | `true` |

### Expected Deployment Time

| Environment   | Duration  | Resources     |
|---------------|-----------|---------------|
| Dev (minimal) | 15-20 min | ~25 resources |
| Int (typical) | 25-35 min | ~40 resources |
| Prod (full)   | 35-50 min | ~60 resources |

**Note**: Times include firewall/gateway deployments which take longest.

## Spoke Workspace Deployment

Spoke workspaces can be deployed:
- **From hub pipeline**: Set `spoke_count` variable
- **Separately**: Use dedicated spoke pipelines

### Deploying Spokes from Hub

Most common approach - spokes created as part of hub deployment:

1. **Set spoke_count** in `terraform-vars-hub-<env>`:
   - `0`: No spokes (hub only)
   - `1`: Alpha spoke
   - `2`: Alpha + Beta spokes
   - `3`: Alpha + Beta + Gamma spokes

2. **Run hub pipeline** as described above
3. **Spokes created automatically** with hub

### Deploying Dedicated Spoke Workspaces

For separate spoke environments (dev, int, prod as independent workspaces):

#### 1. Development Spoke

**Pipeline**: `Sub-TRL-dev-weu-tf`

**Variable Group**: `terraform-vars-spoke-dev`

**Components**:
- Development spoke VNet (10.1.0.0/16)
- Development workload subnets
- Development VMs
- NSGs and security rules
- VNet peering to hub

**Deployment**:
```
Navigate to: Pipelines → Sub-TRL-dev-weu-tf → Run pipeline
Branch: main
Run
```

#### 2. Integration Spoke

**Pipeline**: `Sub-TRL-int-weu-tf`

**Variable Group**: `terraform-vars-spoke-int`

**Components**:
- Integration spoke VNet (10.2.0.0/16)
- Integration workload subnets
- Integration VMs and resources
- Integration testing tools
- VNet peering to hub

**Deployment**: Same as dev, using int pipeline

#### 3. Production Spoke

**Pipeline**: `Sub-TRL-prd-weu-tf`

**Variable Group**: `terraform-vars-spoke-prod`

**Components**:
- Production spoke VNet (10.3.0.0/16)
- Production workload subnets
- Production VMs with HA
- Enhanced security rules
- Backup and DR configuration

**Deployment**: 
- Requires approval gate
- More stringent validation
- Extended testing period

### Spoke Deployment Order

**Recommended order**:
1. Deploy **Hub** first
2. Deploy **Dev spoke**
3. Test and validate
4. Deploy **Int spoke**
5. Test and validate
6. Deploy **Prod spoke** with approvals

### Spoke Post-Deployment Validation

```bash
# Verify spoke VNet
az network vnet show \
  --name vnet-trl-prd-alpha-001 \
  --resource-group rg-trl-prd-alpha-001

# Check VNet peering
az network vnet peering list \
  --resource-group rg-trl-prd-alpha-001 \
  --vnet-name vnet-trl-prd-alpha-001 \
  --output table

# Test VM connectivity (if deployed)
az vm list \
  --resource-group rg-trl-prd-alpha-001 \
  --output table

# Check NSG rules
az network nsg list \
  --resource-group rg-trl-prd-alpha-001 \
  --output table
```

## Management Workspace Deployment

The Management workspace deploys operational tools.

### Management Components

- **Log Analytics Workspace**: Centralized logging
- **Application Insights**: Application monitoring
- **Storage Accounts**: Diagnostic logs and backups
- **Key Vault**: Secrets and certificates
- **Automation Account**: Runbooks and automation
- **Recovery Services Vault**: Backup repository

### Deployment Steps

**Pipeline**: `Sub-TRL-mgmt-weu-tf`

**Variable Group**: `terraform-vars-mgmt-prod`

1. **Navigate to pipeline**: Pipelines → Sub-TRL-mgmt-weu-tf
2. **Run pipeline**: Select main branch
3. **Review plan**: Verify management resources
4. **Approve** (if production)
5. **Monitor apply**: Watch resource creation

### Management Deployment Variables

Key variables:

| Variable                  | Production Value |
|---------------------------|------------------|
| `enable_monitoring`       | `true`           |
| `log_retention_days`      | `365`            |
| `enable_key_vault`        | `true`           |
| `enable_backup`           | `true`           |
| `backup_policy_retention` | `30`             |

### Post-Deployment Configuration

After management workspace deployment:

1. **Configure Log Analytics**:
   ```bash
   # Verify workspace
   az monitor log-analytics workspace show \
     --resource-group rg-trl-prd-mgmt-001 \
     --workspace-name law-trl-prd-001
   
   # Get workspace ID for agents
   az monitor log-analytics workspace show \
     --resource-group rg-trl-prd-mgmt-001 \
     --workspace-name law-trl-prd-001 \
     --query customerId --output tsv
   ```

2. **Configure Key Vault**:
   ```bash
   # Set access policy for admin
   az keyvault set-policy \
     --name kv-trl-prd-<random> \
     --upn admin@company.com \
     --secret-permissions get list set delete
   ```

3. **Set up alerts**:
   - Configure action groups
   - Create alert rules
   - Test notification delivery

## Environment Promotion

### Promoting Changes Across Environments

**Standard promotion path**: Dev → Int → Prod

#### Step 1: Deploy to Development

1. Create feature branch: `feature/new-capability`
2. Make infrastructure changes
3. Update variables in `terraform-vars-hub-dev`
4. Create PR to main
5. Automated dev deployment runs
6. Verify in dev environment

#### Step 2: Test in Development

Validation checklist:
- [ ] All resources created successfully
- [ ] No errors in deployment logs
- [ ] Resources accessible and functional
- [ ] Monitoring data flowing
- [ ] No security issues
- [ ] Cost estimate acceptable

#### Step 3: Promote to Integration

1. Update `terraform-vars-hub-int` with appropriate values
2. Commit changes
3. Run integration pipeline
4. Monitor deployment
5. Perform integration testing

**Integration testing**:
- Component integration tests
- End-to-end scenarios
- Performance testing
- Security scanning

#### Step 4: Promote to Production

1. **Schedule change window**:
   - Notify stakeholders
   - Plan for off-peak hours
   - Prepare rollback plan

2. **Update production variables**:
   - Review `terraform-vars-hub-prod`
   - Ensure production-appropriate values
   - Verify all required variables set

3. **Create production PR**:
   - Detailed description of changes
   - Reference tested environments
   - Include rollback procedure

4. **Review and approval**:
   - Infrastructure team review
   - Security review
   - Management approval

5. **Execute deployment**:
   - Run production pipeline
   - Monitor closely
   - Validate each stage

6. **Post-deployment validation**:
   - Smoke tests
   - Health checks
   - Monitoring validation
   - User acceptance

### Version Control Strategy

```
main (production)
  ↑
  └─ environments/int
       ↑
       └─ environments/dev
            ↑
            └─ feature/xxx
```

**Branch protection**:
- Main: Requires reviews, passing builds, approvals
- Environment branches: Requires reviews, passing builds
- Feature branches: No restrictions

## Rollback Procedures

### When to Rollback

Rollback if:
- ❌ Deployment fails during apply
- ❌ Resources not functioning as expected
- ❌ Security issues discovered
- ❌ Performance degradation observed
- ❌ Unforeseen cost implications

### Rollback Methods

#### Method 1: Terraform State Rollback (Preferred)

If you have the previous state file:

1. **Stop current deployment**:
   - Cancel pipeline if still running
   - Navigate to Azure DevOps pipeline
   - Click "Cancel"

2. **Restore previous state**:
   ```bash
   # Download previous state from backup
   az storage blob download \
     --account-name sttfstateprodweu<random> \
     --container-name tfstate \
     --name hub.tfstate.backup \
     --file hub.tfstate
   
   # Upload as current state
   az storage blob upload \
     --account-name sttfstateprodweu<random> \
     --container-name tfstate \
     --name hub.tfstate \
     --file hub.tfstate \
     --overwrite
   ```

3. **Run Terraform apply with previous configuration**:
   - Revert code to previous commit
   - Run pipeline
   - Terraform will revert to previous state

#### Method 2: Git Revert

Revert to previous working commit:

```bash
# Find last working commit
git log --oneline

# Revert to specific commit
git revert <commit-hash>

# Push revert
git push origin main

# Pipeline automatically deploys reverted state
```

#### Method 3: Manual Resource Deletion

Last resort - manually delete problematic resources:

```bash
# List resources in resource group
az resource list \
  --resource-group rg-trl-prd-hub-001 \
  --output table

# Delete specific resource
az resource delete \
  --resource-group rg-trl-prd-hub-001 \
  --name <resource-name> \
  --resource-type <resource-type>

# Or delete entire resource group (CAUTION!)
az group delete --name rg-trl-prd-hub-001 --yes
```

**Important**: After manual changes, update Terraform state:
```bash
terraform refresh
terraform state rm <resource-address>
```

### Rollback Testing

Test rollback procedures regularly:

1. **Quarterly rollback drill**: Practice in dev environment
2. **Document issues**: Update procedures based on findings
3. **Time the process**: Know how long rollback takes
4. **Automate where possible**: Create rollback scripts

## Monitoring Deployments

### Pipeline Monitoring

#### During Deployment

Monitor these aspects:

1. **Pipeline Logs**:
   - Navigate to pipeline run
   - Click on each stage
   - Review detailed logs
   - Look for errors or warnings

2. **Azure Portal**:
   - Open resource groups
   - Watch resources being created
   - Monitor deployment status
   - Check activity log

3. **Terraform Output**:
   ```
   Apply complete! Resources: 45 added, 0 changed, 0 destroyed.
   
   Outputs:
   hub_vnet_id = "/subscriptions/.../vnet-trl-prd-hub-001"
   hub_vnet_name = "vnet-trl-prd-hub-001"
   spoke_vnet_ids = [...]
   ```

#### Post-Deployment Monitoring

Set up continuous monitoring:

1. **Azure Monitor**:
   ```bash
   # Check resource health
   az resource list \
     --resource-group rg-trl-prd-hub-001 \
     --query "[].{name:name, type:type, location:location}"
   ```

2. **Log Analytics Queries**:
   ```kusto
   AzureActivity
   | where TimeGenerated > ago(1h)
   | where ResourceGroup contains "trl-prd"
   | summarize count() by OperationName, ActivityStatusValue
   | order by count_ desc
   ```

3. **Cost Monitoring**:
   ```bash
   # Check current month costs
   az consumption usage list \
     --start-date $(date -d "1 month ago" +%Y-%m-%d) \
     --end-date $(date +%Y-%m-%d) \
     --query "[].{Date:usageStart, Cost:pretaxCost}"
   ```

### Setting Up Alerts

Configure alerts for deployment issues:

**Pipeline Failure Alert**:
- Trigger: Pipeline fails
- Action: Email infrastructure team
- SLA: Respond within 1 hour

**Resource Creation Alert**:
- Trigger: Resource group created/deleted
- Action: Notify security team
- Purpose: Audit trail

**Cost Alert**:
- Trigger: Daily cost exceeds threshold
- Action: Email finance and infrastructure
- Threshold: 120% of expected daily cost

## Common Deployment Scenarios

### Scenario 1: Initial Environment Setup

**Objective**: Deploy complete hub-spoke infrastructure from scratch

**Steps**:
1. Set up backend storage and service principal
2. Configure variable groups for environment
3. Deploy hub workspace
4. Validate hub deployment
5. Deploy spoke workspaces
6. Deploy management workspace
7. Configure monitoring and alerts
8. Perform end-to-end testing

**Duration**: 2-4 hours (including validation)

### Scenario 2: Add New Spoke Network

**Objective**: Add additional spoke to existing hub

**Steps**:
1. Update `spoke_count` in hub variables:
   ```yaml
   spoke_count: 3  # Was 2, now 3
   ```
2. Run hub pipeline
3. Plan shows new spoke resources
4. Approve and apply
5. Validate new spoke:
   - VNet created
   - Peering established
   - Subnets configured
   - Resources deployed

**Duration**: 20-30 minutes

### Scenario 3: Enable New Feature (e.g., Azure Firewall)

**Objective**: Enable Azure Firewall in existing hub

**Steps**:
1. Update hub variables:
   ```yaml
   enable_firewall: true  # Was false
   firewall_sku: Premium  # Optional
   ```
2. Run hub pipeline
3. Review plan - firewall and dependencies
4. Approve deployment
5. Configure firewall rules post-deployment
6. Update route tables
7. Test traffic flow

**Duration**: 30-40 minutes (firewall deployment is slow)

### Scenario 4: Update VM Sizes

**Objective**: Resize VMs across environment

**Steps**:
1. Update variables:
   ```yaml
   vm_size: Standard_D4s_v5  # Was Standard_D2s_v5
   ```
2. Run pipeline
3. Plan shows VM recreation
4. **Schedule downtime** (VMs will be recreated)
5. Approve deployment
6. VMs recreated with new size
7. Validate applications

**Duration**: 15-20 minutes + application startup time

**Important**: VM recreation causes downtime!

### Scenario 5: Disaster Recovery Failover

**Objective**: Failover to secondary region

**Steps**:
1. Update variables:
   ```yaml
   location: North Europe  # Was West Europe
   ```
2. Update backend key for DR deployment:
   ```yaml
   backendKey: hub-dr.tfstate  # Separate state for DR
   ```
3. Run deployment to secondary region
4. Validate resources in secondary region
5. Update DNS/Traffic Manager
6. Redirect traffic
7. Monitor application health

**Duration**: 45-60 minutes

## Troubleshooting

### Common Issues

#### Issue: Backend Initialization Failed

**Error**:
```
Error: Failed to get existing workspaces: storage: service returned error:
StatusCode=403, ErrorCode=AuthorizationFailure
```

**Solution**:
1. Verify service principal has Storage Blob Data Contributor role:
   ```bash
   az role assignment create \
     --assignee <service-principal-id> \
     --role "Storage Blob Data Contributor" \
     --scope /subscriptions/<sub-id>/resourceGroups/<backend-rg>/providers/Microsoft.Storage/storageAccounts/<backend-sa>
   ```
2. Retry pipeline

#### Issue: Resource Already Exists

**Error**:
```
Error: A resource with the ID "/subscriptions/.../resourceGroups/rg-trl-prd-hub-001" already exists
```

**Solution**:
1. Import existing resource into state:
   ```bash
   terraform import azurerm_resource_group.hub /subscriptions/.../resourceGroups/rg-trl-prd-hub-001
   ```
2. Or delete existing resource:
   ```bash
   az group delete --name rg-trl-prd-hub-001 --yes
   ```
3. Re-run pipeline

#### Issue: Terraform Version Mismatch

**Error**:
```
Error: Unsupported Terraform Core version
```

**Solution**:
1. Update pipeline Terraform installer task:
   ```yaml
   - task: TerraformInstaller@0
     inputs:
       terraformVersion: '1.13.4'  # Match required version
   ```
2. Re-run pipeline

#### Issue: Variable Not Found

**Error**:
```
Error: Required variable not set: admin_password
```

**Solution**:
1. Check variable group is linked in pipeline YAML
2. Verify variable exists in correct group
3. Ensure variable name spelling matches
4. Re-run pipeline

#### Issue: Quota Exceeded

**Error**:
```
Error: Operation results in exceeding quota limits of Core
```

**Solution**:
1. Check current quota:
   ```bash
   az vm list-usage --location westeurope --output table
   ```
2. Request quota increase in Azure Portal
3. Or deploy to different region
4. Or reduce vm_size/count

#### Issue: Timeout During Apply

**Error**:
```
Error: Job timeout exceeded
```

**Solution**:
1. Increase pipeline timeout:
   ```yaml
   jobs:
     - job: TerraformApply
       timeoutInMinutes: 120  # Increase from default 60
   ```
2. Use faster SKUs for resources
3. Deploy in stages if necessary

### Getting Help

1. **Check pipeline logs**: Full error details in logs
2. **Review Terraform documentation**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
3. **Azure documentation**: https://docs.microsoft.com/azure/
4. **Internal documentation**: Project README and guides
5. **Team communication**: Slack/Teams for quick questions
6. **Create issue**: For persistent problems, document in repository issues

## Best Practices

### Deployment Best Practices

1. **Always review plan before apply**
   - Never blindly approve
   - Understand what will change
   - Verify expected resources

2. **Use descriptive commit messages**
   - Clear purpose of changes
   - Reference work items
   - Include context

3. **Test in lower environments first**
   - Dev → Int → Prod
   - Never skip environments
   - Full testing in each

4. **Schedule production changes**
   - Off-peak hours
   - Change windows
   - Stakeholder notification

5. **Have rollback plan ready**
   - Know how to revert
   - Practice rollbacks
   - Document procedures

6. **Monitor deployments actively**
   - Watch logs in real-time
   - Check Azure Portal
   - Validate resources

7. **Document changes**
   - Update documentation
   - Record decisions
   - Share knowledge

### Security Best Practices

1. **Protect sensitive variables**
   - Mark as secret
   - Use Key Vault
   - Rotate regularly

2. **Limit pipeline permissions**
   - Least privilege
   - Separate environments
   - Regular audits

3. **Enable approval gates**
   - Production requires approval
   - Multiple approvers
   - Document approvals

4. **Audit deployments**
   - Review logs
   - Track changes
   - Monitor access

### Cost Optimization

1. **Right-size resources**
   - Match size to workload
   - Use burstable VMs for dev
   - Scale based on demand

2. **Use auto-shutdown**
   - Dev/Int environments
   - Off-hours shutdown
   - Significant cost savings

3. **Monitor costs**
   - Set budgets
   - Configure alerts
   - Regular reviews

4. **Clean up unused resources**
   - Remove old test resources
   - Delete unused snapshots
   - Optimize storage

## Next Steps

After successful deployment:

1. ✅ **Configure applications**: Deploy apps to infrastructure
2. ✅ **Set up monitoring**: Configure detailed monitoring and alerts
3. ✅ **Implement backup**: Configure Azure Backup policies
4. ✅ **Security hardening**: Apply additional security controls
5. ✅ **Documentation**: Update runbooks and procedures
6. ✅ **Training**: Train team on new infrastructure
7. ✅ **Optimization**: Review and optimize configurations

## Additional Resources

- [PIPELINE-SETUP-GUIDE.md](PIPELINE-SETUP-GUIDE.md) - Pipeline setup instructions
- [PIPELINE-VARIABLES-GUIDE.md](PIPELINE-VARIABLES-GUIDE.md) - Variable reference
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [WINDOWS-AGENT-SETUP.md](WINDOWS-AGENT-SETUP.md) - Agent configuration
- [PARALLELISM-ERROR-FIX.md](PARALLELISM-ERROR-FIX.md) - Troubleshooting parallelism issues
- [Azure DevOps Documentation](https://docs.microsoft.com/azure/devops/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

