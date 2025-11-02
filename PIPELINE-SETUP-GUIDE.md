# Pipeline Setup Guide

This guide provides detailed instructions for setting up Azure DevOps pipelines for the Azure Hub-Spoke Infrastructure as Code (IaC) project.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Azure DevOps Project Setup](#azure-devops-project-setup)
- [Service Connection Configuration](#service-connection-configuration)
- [Variable Group Setup](#variable-group-setup)
- [Repository Configuration](#repository-configuration)
- [Pipeline Creation](#pipeline-creation)
- [Agent Pool Setup](#agent-pool-setup)
- [Pipeline Security](#pipeline-security)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before setting up the pipelines, ensure you have:

### Required Access

- **Azure Subscription**: Owner or Contributor role
- **Azure DevOps**: Project Administrator or Build Administrator role
- **Service Principal**: Created with appropriate permissions

### Required Tools

- Azure CLI (latest version)
- Azure DevOps CLI extension (optional but recommended)
- Git for version control
- Text editor for YAML editing

### Azure Resources

The following resources should be created before pipeline setup:

1. **Storage Account** for Terraform state
   - Name: `st<env><location><random>`
   - Container: `tfstate`
   - Access: Service Principal has Storage Blob Data Contributor role

2. **Resource Group** for Terraform backend
   - Name: `rg-terraform-state-<env>`
   - Location: Same as deployment region

3. **Service Principal** for deployments
   - Name: `sp-terraform-<env>`
   - Permissions: Contributor on subscription
   - Client Secret: Stored securely

## Azure DevOps Project Setup

### 1. Create Azure DevOps Project

1. Navigate to your Azure DevOps organization
2. Click **"New Project"**
3. Configure project settings:
   - **Project name**: `Azure-IAC-HubSpoke`
   - **Visibility**: Private (recommended)
   - **Version control**: Git
   - **Work item process**: Agile
4. Click **"Create"**

### 2. Configure Project Settings

1. Navigate to **Project Settings** → **Repositories**
2. Enable the following:
   - Commit mention linking
   -  Commit mention work item resolution
   -  Work item transition preferences

3. Navigate to **Project Settings** → **Pipelines**
4. Configure pipeline settings:
   -  Disable creation of classic build pipelines
   -  Disable creation of classic release pipelines
   -  Limit job authorization scope to current project

## Service Connection Configuration

### Create Azure Service Connection

A service connection allows Azure DevOps to authenticate with Azure.

#### Method 1: Using Azure Portal and Azure DevOps UI

1. **Create Service Principal in Azure**:
   ```bash
   # Login to Azure
   az login
   
   # Set subscription
   az account set --subscription <subscription-id>
   
   # Create service principal
   az ad sp create-for-rbac --name "sp-terraform-devops" \
     --role Contributor \
     --scopes /subscriptions/<subscription-id>
   ```


1. **Create Service Connection in Azure DevOps**:
   - Navigate to **Project Settings** → **Service connections**
   - Click **"New service connection"**
   - Select **"Azure Resource Manager"**
   - Choose **"Service principal (manual)"**
   - Fill in the details:
     - **Subscription ID**: Your Azure subscription ID
     - **Subscription Name**: Your subscription name
     - **Service Principal Id**: The `appId` from step 1
     - **Service Principal Key**: The `password` from step 1
     - **Tenant ID**: The `tenant` from step 1
   - **Service connection name**: `Azure-Terraform-Connection`
   - **Description**: `Service connection for Terraform deployments`
   - Grant access permission to all pipelines (or configure per pipeline)
   - Click **"Verify and save"**

#### Method 2: Using Azure CLI

```bash
# Login to both Azure and Azure DevOps
az login
az devops login

# Set default organization and project
az devops configure --defaults organization=https://dev.azure.com/YourOrg project=Azure-IAC-HubSpoke

# Create service endpoint
az devops service-endpoint azurerm create \
  --azure-rm-service-principal-id <appId> \
  --azure-rm-subscription-id <subscription-id> \
  --azure-rm-subscription-name "Your Subscription Name" \
  --azure-rm-tenant-id <tenant-id> \
  --name "Azure-Terraform-Connection"
```

### Verify Service Connection

1. Navigate to **Project Settings** → **Service connections**
2. Select your connection
3. Click **"Verify"** to ensure connectivity
4. Check **"Manage Service Principal"** to review Azure permissions

### Grant Additional Permissions (if needed)

If deploying specific resources, the service principal may need additional roles:

```bash
# User Access Administrator (for role assignments)
az role assignment create \
  --assignee <appId> \
  --role "User Access Administrator" \
  --scope /subscriptions/<subscription-id>

# Network Contributor (for network resources)
az role assignment create \
  --assignee <appId> \
  --role "Network Contributor" \
  --scope /subscriptions/<subscription-id>

# Storage Blob Data Contributor (for backend state)
az role assignment create \
  --assignee <appId> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<subscription-id>/resourceGroups/<backend-rg>/providers/Microsoft.Storage/storageAccounts/<backend-sa>
```

## Variable Group Setup

Variable groups store configuration values used across pipelines.

### Create Variable Groups

#### 1. Terraform Backend Variables

1. Navigate to **Pipelines** → **Library** → **+ Variable group**
2. Create group: `terraform-backend-dev`
3. Add variables:

   | Variable Name               | Value                     | Secret |
   |-----------------------------|---------------------------|--------|
   | `backendResourceGroupName`  | `rg-terraform-state-dev`  | No     |
   | `backendStorageAccountName` | `sttfstatedevweu<random>` | No     |
   | `backendContainerName`      | `tfstate`                 | No     |
   | `backendKey`                | `hub.tfstate`             | No     |

4. Click **"Save"**

Repeat for `int` and `prod` environments with appropriate values.

#### 2. Azure Credentials Variables

1. Create group: `azure-credentials-dev`
2. Add variables:

   | Variable Name         | Value                          | Secret |
   |-----------------------|--------------------------------|--------|
   | `ARM_SUBSCRIPTION_ID` | `<subscription-id>`            | No     |
   | `ARM_TENANT_ID`       | `<tenant-id>`                  | No     |
   | `ARM_CLIENT_ID`       | `<service-principal-app-id>`   | No     |
   | `ARM_CLIENT_SECRET`   | `<service-principal-password>` | Yes    |

   **Important**: Mark `ARM_CLIENT_SECRET` as secret!

3. Click **"Save"**

Repeat for `int` and `prod` environments.

#### 3. Environment-Specific Variables

1. Create group: `terraform-vars-hub-dev`
2. Add variables:

   | Variable Name     | Value                        | Secret |
   |-------------------|------------------------------|--------|
   | `environment`     | `dev`                        | No     |
   | `location`        | `West Europe`                | No     |
   | `spoke_count`     | `2`                          | No     |
   | `enable_firewall` | `false`                      | No     |
   | `enable_bastion`  | `true`                       | No     |
   | `vm_size`         | `Standard_B1s`               | No     |
   | `admin_username`  | `azureuser`                  | No     |
   | `admin_password`  | `<secure-password>`          | Yes    |
   | `created_by`      | `DevOps Pipeline`            | No     |
   | `owner_email`     | `infrastructure@company.com` | No     |
   | `cost_center`     | `IT-INFRA-001`               | No     |

3. Click **"Save"**

Repeat for other workspaces (management, spokes) and environments.

### Link Variable Groups to Pipelines

Variable groups will be referenced in pipeline YAML:

```yaml
variables:
  - group: terraform-backend-dev
  - group: azure-credentials-dev
  - group: terraform-vars-hub-dev
```

## Repository Configuration

### Import Repository

1. Navigate to **Repos** → **Files**
2. Click **"Import repository"**
3. Enter the clone URL of your repository
4. Click **"Import"**

### Configure Branch Policies

Protect the `main` branch:

1. Navigate to **Repos** → **Branches**
2. Click the **"..."** next to `main` → **Branch policies**
3. Configure:
   -  Require a minimum number of reviewers: **1**
   -  Check for linked work items: **Optional**
   -  Check for comment resolution: **Required**
   -  Limit merge types: **Squash merge only**

4. Add **Build validation**:
   - Click **"+ Add build policy"**
   - Select pipeline: `Hub-Dev-Plan`
   - **Trigger**: Automatic
   - **Policy requirement**: Required
   - **Build expiration**: Immediately
   - Click **"Save"**

### Set Up Branch Structure

```bash
# Clone repository
git clone https://dev.azure.com/YourOrg/Azure-IAC-HubSpoke/_git/Azure.IAC.hubspoke
cd Azure.IAC.hubspoke

# Create and push develop branch
git checkout -b develop
git push -u origin develop

# Create environment branches
git checkout -b environments/dev
git push -u origin environments/dev

git checkout -b environments/int
git push -u origin environments/int

git checkout -b environments/prod
git push -u origin environments/prod
```

## Pipeline Creation

### Pipeline File Structure

The repository includes pipeline files in `pipelines/Subscription pipeline/`:

- `Sub-TRL-hub-weu-tf.yml` - Hub workspace deployment
- `Sub-TRL-dev-weu-tf.yml` - Dev spoke deployment
- `Sub-TRL-int-weu-tf.yml` - Int spoke deployment
- `Sub-TRL-prd-weu-tf.yml` - Prod spoke deployment
- `Sub-TRL-mgmt-weu-tf.yml` - Management workspace
- `terraform-init.yml` - Shared initialization template

### Create Hub Pipeline

1. Navigate to **Pipelines** → **Pipelines**
2. Click **"New pipeline"**
3. Select **"Azure Repos Git"**
4. Select your repository
5. Select **"Existing Azure Pipelines YAML file"**
6. Choose branch: `main`
7. Path: `/pipelines/Subscription pipeline/Sub-TRL-hub-weu-tf.yml`
8. Click **"Continue"**
9. Review the YAML
10. Click **"Run"** or **"Save"**

#### Sample Hub Pipeline (Sub-TRL-hub-weu-tf.yml)

```yaml
# Pipeline for Hub Workspace Deployment
name: Hub-$(environment)-$(Date:yyyyMMdd)$(Rev:.r)

trigger:
  branches:
    include:
      - main
  paths:
    include:
      - workspaces/hub/*
      - modules/*

pr:
  branches:
    include:
      - main
  paths:
    include:
      - workspaces/hub/*
      - modules/*

variables:
  - group: terraform-backend-prod
  - group: azure-credentials-prod
  - group: terraform-vars-hub-prod
  - name: workspacePath
    value: 'workspaces/hub'
  - name: environment
    value: 'prod'
  - name: terraformVersion
    value: '1.13.4'

pool:
  vmImage: 'windows-latest'

stages:
  - stage: Validate
    displayName: 'Validate Terraform Configuration'
    jobs:
      - job: TerraformValidate
        displayName: 'Terraform Validate'
        steps:
          - task: TerraformInstaller@0
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: $(terraformVersion)

          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(System.DefaultWorkingDirectory)/$(workspacePath)'
              backendServiceArm: 'Azure-Terraform-Connection'
              backendAzureRmResourceGroupName: '$(backendResourceGroupName)'
              backendAzureRmStorageAccountName: '$(backendStorageAccountName)'
              backendAzureRmContainerName: '$(backendContainerName)'
              backendAzureRmKey: 'hub.tfstate'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Validate'
            inputs:
              provider: 'azurerm'
              command: 'validate'
              workingDirectory: '$(System.DefaultWorkingDirectory)/$(workspacePath)'

  - stage: Plan
    displayName: 'Terraform Plan'
    dependsOn: Validate
    jobs:
      - job: TerraformPlan
        displayName: 'Terraform Plan'
        steps:
          - task: TerraformInstaller@0
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: $(terraformVersion)

          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(System.DefaultWorkingDirectory)/$(workspacePath)'
              backendServiceArm: 'Azure-Terraform-Connection'
              backendAzureRmResourceGroupName: '$(backendResourceGroupName)'
              backendAzureRmStorageAccountName: '$(backendStorageAccountName)'
              backendAzureRmContainerName: '$(backendContainerName)'
              backendAzureRmKey: 'hub.tfstate'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              workingDirectory: '$(System.DefaultWorkingDirectory)/$(workspacePath)'
              environmentServiceNameAzureRM: 'Azure-Terraform-Connection'
              commandOptions: '-out=$(System.DefaultWorkingDirectory)/$(workspacePath)/tfplan'

          - task: PublishPipelineArtifact@1
            displayName: 'Publish Plan Artifact'
            inputs:
              targetPath: '$(System.DefaultWorkingDirectory)/$(workspacePath)/tfplan'
              artifact: 'tfplan-$(environment)'
              publishLocation: 'pipeline'

  - stage: Apply
    displayName: 'Terraform Apply'
    dependsOn: Plan
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: TerraformApply
        displayName: 'Terraform Apply'
        environment: 'Hub-Production'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - task: TerraformInstaller@0
                  displayName: 'Install Terraform'
                  inputs:
                    terraformVersion: $(terraformVersion)

                - task: DownloadPipelineArtifact@2
                  displayName: 'Download Plan Artifact'
                  inputs:
                    artifact: 'tfplan-$(environment)'
                    path: '$(System.DefaultWorkingDirectory)/$(workspacePath)'

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Init'
                  inputs:
                    provider: 'azurerm'
                    command: 'init'
                    workingDirectory: '$(System.DefaultWorkingDirectory)/$(workspacePath)'
                    backendServiceArm: 'Azure-Terraform-Connection'
                    backendAzureRmResourceGroupName: '$(backendResourceGroupName)'
                    backendAzureRmStorageAccountName: '$(backendStorageAccountName)'
                    backendAzureRmContainerName: '$(backendContainerName)'
                    backendAzureRmKey: 'hub.tfstate'

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Apply'
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    workingDirectory: '$(System.DefaultWorkingDirectory)/$(workspacePath)'
                    environmentServiceNameAzureRM: 'Azure-Terraform-Connection'
                    commandOptions: '$(System.DefaultWorkingDirectory)/$(workspacePath)/tfplan'
```

### Create Additional Pipelines

Repeat the pipeline creation process for:

1. **Development Spoke Pipeline**:
   - File: `Sub-TRL-dev-weu-tf.yml`
   - Variable groups: `*-dev`
   - Environment: `Spoke-Development`

2. **Integration Spoke Pipeline**:
   - File: `Sub-TRL-int-weu-tf.yml`
   - Variable groups: `*-int`
   - Environment: `Spoke-Integration`

3. **Production Spoke Pipeline**:
   - File: `Sub-TRL-prd-weu-tf.yml`
   - Variable groups: `*-prod`
   - Environment: `Spoke-Production`

4. **Management Pipeline**:
   - File: `Sub-TRL-mgmt-weu-tf.yml`
   - Variable groups: `*-mgmt`
   - Environment: `Management-Production`

### Configure Environments

Create approval gates for production deployments:

1. Navigate to **Pipelines** → **Environments**
2. Click **"New environment"**
3. Name: `Hub-Production`
4. Click **"Create"**
5. Click **"..."** → **Approvals and checks**
6. Click **"+ Add check"** → **"Approvals"**
7. Add approvers (e.g., infrastructure team leads)
8. Configure:
   - **Approvers**: Select users/groups
   - **Timeout**: 30 days
   -  Requester cannot approve
   - **Instructions**: "Review Terraform plan before approving"
9. Click **"Save"**

Repeat for other production environments.

## Agent Pool Setup

### Option 1: Microsoft-Hosted Agents

Use Azure-provided agents (recommended for getting started):

```yaml
pool:
  vmImage: 'windows-latest'  # or 'ubuntu-latest'
```

**Pros:**
- No maintenance required
- Always up-to-date
- Scales automatically

**Cons:**
- Limited customization
- No persistent state
- May have network restrictions

### Option 2: Self-Hosted Windows Agent

For custom requirements or network restrictions, set up self-hosted agents.

#### Prerequisites

- Windows Server 2019/2022 or Windows 10/11
- PowerShell 5.1 or later
- .NET Framework 4.6.2 or later
- Administrator access

#### Installation Steps

See [WINDOWS-AGENT-SETUP.md](WINDOWS-AGENT-SETUP.md) for detailed instructions.

Quick setup:

```powershell
# Download and install agent
New-Item -Path "C:\agents" -ItemType Directory -Force
Set-Location "C:\agents"

# Download agent package
Invoke-WebRequest -Uri "https://vstsagentpackage.azureedge.net/agent/3.232.3/vsts-agent-win-x64-3.232.3.zip" -OutFile "agent.zip"

# Extract
Expand-Archive -Path "agent.zip" -DestinationPath "."

# Configure
.\config.cmd

# Install as service
.\config.cmd --unattended --runAsService
```

#### Configure Agent Pool

1. Navigate to **Project Settings** → **Agent pools**
2. Click **"Add pool"**
3. Select **"New"**
4. **Pool type**: Self-hosted
5. **Name**: `Terraform-Agents`
6.  Grant access permission to all pipelines
7. Click **"Create"**

Update pipeline to use custom pool:

```yaml
pool:
  name: 'Terraform-Agents'
```

## Pipeline Security

### Secure Variable Management

1. **Use Variable Groups** for sensitive data
2. **Mark secrets** appropriately (lock icon)
3. **Limit access** to variable groups
4. **Use Azure Key Vault** for highly sensitive data

#### Integrate Azure Key Vault

1. Create Key Vault in Azure:
   ```bash
   az keyvault create \
     --name kv-terraform-secrets \
     --resource-group rg-devops-shared \
     --location westeurope
   ```

2. Grant service principal access:
   ```bash
   az keyvault set-policy \
     --name kv-terraform-secrets \
     --spn <service-principal-id> \
     --secret-permissions get list
   ```

3. Link to Variable Group:
   - Navigate to **Pipelines** → **Library**
   - Edit variable group
   - Click **"Link secrets from an Azure key vault as variables"**
   - Select service connection
   - Select Key Vault
   - Authorize and choose secrets
   - Click **"Save"**

### Pipeline Permissions

Configure who can edit and run pipelines:

1. Navigate to **Pipelines** → **Pipelines**
2. Select pipeline → **"..."** → **Security**
3. Configure permissions:
   - **Administrators**: Full control
   - **Contributors**: Queue builds, edit build pipeline
   - **Readers**: View builds and build pipeline

### Audit and Compliance

Enable audit logging:

1. Navigate to **Project Settings** → **Auditing**
2. Review audit events regularly
3. Export logs for compliance

## Troubleshooting

### Common Issues

#### Issue: Service Connection Fails Verification

**Solution:**
```bash
# Verify service principal credentials
az login --service-principal \
  -u <client-id> \
  -p <client-secret> \
  --tenant <tenant-id>

# Check role assignments
az role assignment list --assignee <client-id>
```

#### Issue: Terraform Init Fails - Backend Access Denied

**Solution:**
```bash
# Grant Storage Blob Data Contributor role
az role assignment create \
  --assignee <service-principal-id> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/<backend-rg>/providers/Microsoft.Storage/storageAccounts/<backend-sa>
```

#### Issue: Pipeline Runs Slowly or Times Out

**Solution:**
- Increase pipeline timeout in YAML:
  ```yaml
  jobs:
    - job: TerraformApply
      timeoutInMinutes: 120  # Default is 60
  ```
- Use self-hosted agents for better performance
- Optimize Terraform with parallelism:
  ```yaml
  commandOptions: '-parallelism=10'
  ```

#### Issue: Variable Not Found in Pipeline

**Solution:**
- Ensure variable group is linked in pipeline YAML
- Check variable group permissions
- Verify variable name spelling and casing

### Getting Help

1. Review Azure DevOps pipeline logs
2. Enable **System.Debug** variable for detailed logs
3. Check [Azure DevOps documentation](https://docs.microsoft.com/azure/devops/)
4. Review project-specific documentation in repository

## Next Steps

After completing the pipeline setup:

1.  Review [PIPELINE-VARIABLES-GUIDE.md](PIPELINE-VARIABLES-GUIDE.md) for variable configuration
2.  Read [PIPELINE-DEPLOYMENT-GUIDE.md](PIPELINE-DEPLOYMENT-GUIDE.md) for deployment procedures
3.  Test pipelines in development environment
4.  Configure monitoring and alerting
5.  Set up automated testing

## Additional Resources

- [Azure DevOps Documentation](https://docs.microsoft.com/azure/devops/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Naming Conventions](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [WINDOWS-AGENT-SETUP.md](WINDOWS-AGENT-SETUP.md) - Windows agent configuration

