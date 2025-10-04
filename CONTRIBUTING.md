# Contributing to TRL Hub and Spoke Azure Infrastructure

Thank you for your interest in contributing to the TRL Hub and Spoke Azure Infrastructure project! This document provides guidelines and instructions for contributing to this Terraform-based Azure infrastructure project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment Setup](#development-environment-setup)
- [Contribution Guidelines](#contribution-guidelines)
- [Naming Conventions](#naming-conventions)
- [Terraform Standards](#terraform-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Security Considerations](#security-considerations)

## Code of Conduct

This project adheres to a code of conduct that we expect all contributors to follow:

- **Be respectful**: Treat all community members with respect and kindness
- **Be inclusive**: Welcome newcomers and help them get started
- **Be collaborative**: Work together to solve problems and improve the project
- **Be constructive**: Provide helpful feedback and suggestions
- **Be professional**: Maintain professional communication in all interactions

## Getting Started

### Prerequisites

Before contributing, ensure you have the following tools installed:

- **Terraform**: Version 1.5.7 or later
- **Azure CLI**: Latest version
- **Git**: For version control
- **Code Editor**: VS Code with Terraform extension recommended
- **Azure Subscription**: With appropriate permissions

### Required Knowledge

Contributors should have familiarity with:

- Azure cloud services and networking concepts
- Terraform Infrastructure as Code (IaC)
- Hub and Spoke network topology
- Azure security best practices
- Git version control workflows

## Development Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Chidieberetech/Azure-DevOps.git
cd azure-hubspoke-infrastructure
```

### 2. Set Up Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Create service principal for Terraform
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" --scopes="/subscriptions/your-subscription-id"
```

### 3. Configure Authentication for Azure DevOps

Since this project uses Azure DevOps connected to Azure, you have several authentication options:

#### Option A: Azure DevOps Service Connection (Recommended for Pipelines)

When working with Azure DevOps pipelines, authentication is handled automatically through service connections:

```yaml
# In your Azure DevOps pipeline
variables:
  - group: trl-hubspoke-variables  # Variable group containing secrets
  - name: azureSubscription
    value: 'trl-hubspoke-service-connection'  # Service connection name

steps:
- task: AzureCLI@2
  displayName: 'Terraform Operations'
  inputs:
    azureSubscription: $(azureSubscription)
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      cd terraform/environments/dev
      terraform init
      terraform plan
```

#### Option B: Azure CLI Authentication (Local Development)

For local development, use Azure CLI with your Azure DevOps organization:

```bash
# Login to Azure using your Azure DevOps account
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Verify authentication
az account show
```

#### Option C: Managed Identity (Azure DevOps Hosted Agents)

If using Azure DevOps hosted agents with managed identity:

```yaml
# No additional authentication needed - handled by Azure DevOps
steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: $(azureSubscription)
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # Authentication is automatic
      terraform init
```

#### Option D: Azure DevOps Variable Groups

Store sensitive values in Azure DevOps Library > Variable Groups:

1. **Create Variable Group**:
   - Navigate to Azure DevOps > Library > Variable Groups
   - Create group: `trl-hubspoke-variables`
   - Add variables:
     - `AZURE_SUBSCRIPTION_ID` (linked to Azure Key Vault)
     - `AZURE_TENANT_ID` (linked to Azure Key Vault)

2. **Reference in Pipeline**:
```yaml
variables:
  - group: trl-hubspoke-variables

steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: 'trl-hubspoke-service-connection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # Variables are automatically available
      echo "Subscription: $(AZURE_SUBSCRIPTION_ID)"
      terraform init
```

#### Option E: Azure Key Vault Integration

Link your variable group to Azure Key Vault for enhanced security:

1. **Enable Key Vault Integration**:
   - In Variable Groups, toggle "Link secrets from an Azure key vault"
   - Select your Key Vault service connection
   - Choose secrets to import

2. **Pipeline Usage**:
```yaml
variables:
  - group: trl-hubspoke-keyvault-secrets

steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: $(azureSubscription)
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # Secrets automatically available from Key Vault
      terraform init -backend-config="client_secret=$(terraform-sp-secret)"
```

### Setting Up Azure DevOps Service Connection

1. **Navigate to Project Settings**:
   - Go to your Azure DevOps project
   - Select "Project settings" > "Service connections"

2. **Create Azure Resource Manager Connection**:
   ```
   Connection name: trl-hubspoke-service-connection
   Scope level: Subscription
   Subscription: your-azure-subscription
   Resource group: (leave empty for subscription-level)
   Service principal: (automatically created)
   ```

3. **Grant Permissions**:
   - Ensure the service principal has "Contributor" role
   - Add "Key Vault Administrator" for Key Vault operations
   - Grant access to specific resource groups as needed

### Local Development Without Environment Variables

For local development, you can avoid manual environment variable setup:

```bash
# Method 1: Use Azure CLI default credentials
az login
cd terraform/environments/dev
terraform init  # Uses az cli credentials automatically

# Method 2: Use Azure DevOps Personal Access Token
az devops configure --defaults organization=https://dev.azure.com/YourOrg
az devops login
```

### Terraform Backend Configuration for Azure DevOps

Update your backend configuration to work with Azure DevOps:

```hcl
# terraform/environments/prod/main.tf
terraform {
  backend "azurerm" {
    # These can be set via pipeline variables instead of environment variables
    resource_group_name  = "trl-hubspoke-tfstate-rg"
    storage_account_name = "trlhubspoketfstate"
    container_name      = "tfstate"
    key                 = "prod.terraform.tfstate"
    
    # Authentication handled by Azure DevOps service connection
    # No need for client_id, client_secret, etc.
  }
}
```

## Contribution Guidelines

### Types of Contributions

We welcome the following types of contributions:

1. **Bug fixes**: Fixing issues in existing Terraform configurations
2. **Feature additions**: Adding new Azure resources or capabilities
3. **Documentation improvements**: Enhancing README, comments, or guides
4. **Security enhancements**: Improving security posture and compliance
5. **Performance optimizations**: Improving resource efficiency and cost
6. **Testing improvements**: Adding or enhancing validation tests

### Before You Start

1. **Check existing issues**: Review open issues to avoid duplication
2. **Create an issue**: For new features or major changes, create an issue first
3. **Discuss your approach**: Get feedback on your proposed solution
4. **Follow conventions**: Adhere to our naming and coding standards

## Naming Conventions

### TRL Standard Naming Convention

All Azure resources must follow the TRL naming convention:

```
<org>-<project>-<env>-<resourceType>[-<suffix>]
```

**Example**: `trl-hubspoke-prod-vm-web01`

### Components:
- **Organization**: Always `trl`
- **Project**: `Azure.IAC.hubspoke`
- **Environment**: `dev`, `staging`, `prod`
- **Resource Type**: Use approved abbreviations (see README.md)
- **Suffix**: Optional descriptive suffix

### Variable Naming

```hcl
# Good
variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

# Bad
variable "vnet" {
  type = string
}
```

### Resource Naming in Terraform

```hcl
# Good
resource "azurerm_virtual_network" "hub" {
  name = var.hub_vnet_name
  # ...
}

# Bad
resource "azurerm_virtual_network" "vnet1" {
  name = "my-vnet"
  # ...
}
```

## Terraform Standards

### File Organization

```
terraform/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/
│   ├── network/
│   ├── security/
│   ├── compute/
│   └── storage/
```

### Module Structure

Each module must include:

```
module_name/
├── main.tf          # Primary resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider requirements
└── README.md        # Module documentation
```

### Code Style Guidelines

#### 1. Formatting

```bash
# Always format your code
terraform fmt -recursive
```

#### 2. Variable Definitions

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "Resource group name cannot be empty."
  }
}
```

#### 3. Resource Blocks

```hcl
resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.hub_address_space
  
  tags = merge(var.tags, {
    Purpose = "Hub Network"
  })
}
```

#### 4. Comments

```hcl
# Hub Virtual Network for shared services
resource "azurerm_virtual_network" "hub" {
  # Configuration details...
}
```

### Security Requirements

#### 1. No Hardcoded Values

```hcl
# Good
admin_password = data.azurerm_key_vault_secret.vm_password.value

# Bad
admin_password = "Password123!"
```

#### 2. Use Data Sources for Sensitive Information

```hcl
data "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  key_vault_id = var.key_vault_id
}
```

#### 3. Implement Least Privilege

```hcl
# Minimal required permissions only
access_policy {
  tenant_id = var.tenant_id
  object_id = var.object_id
  
  secret_permissions = [
    "Get"
  ]
}
```

## Testing Requirements

### Pre-commit Checks

Before submitting, run:

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Security scan
tfsec .

# Plan without applying
terraform plan
```

### Validation Tests

Include validation blocks where appropriate:

```hcl
variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
  
  validation {
    condition = contains([
      "Standard_B1s",
      "Standard_B2s",
      "Standard_D2s_v3"
    ], var.vm_size)
    error_message = "VM size must be from the approved list."
  }
}
```

### Environment Testing

Test your changes in the development environment:

```bash
cd terraform/environments/dev
terraform plan
terraform apply
# Verify functionality
terraform destroy
```

## Pull Request Process

### 1. Branch Naming

Use descriptive branch names:

```
feature/add-cosmos-db-module
bugfix/firewall-rule-typo
docs/update-readme-examples
security/implement-private-endpoints
```

### 2. Commit Messages

Follow conventional commit format:

```
feat: add Azure Cosmos DB module with private endpoint
fix: correct firewall policy rule priority
docs: update naming convention examples
security: implement Key Vault private endpoint
```

### 3. Pull Request Template

Include the following in your PR description:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Code formatted with terraform fmt
- [ ] Configuration validated
- [ ] Security scan passed
- [ ] Tested in dev environment

## Checklist
- [ ] Follows TRL naming conventions
- [ ] Includes appropriate documentation
- [ ] No hardcoded secrets or credentials
- [ ] Backward compatible (or breaking change noted)
```

### 4. Review Process

1. **Automated checks**: CI/CD pipeline runs validation
2. **Security review**: Security team reviews for compliance
3. **Code review**: Maintainers review code quality and standards
4. **Approval**: Two approvals required for merge to main

## Issue Reporting

### Bug Reports

Include the following information:

```markdown
**Environment**: dev/staging/prod
**Terraform Version**: x.x.x
**Azure CLI Version**: x.x.x
**Module**: network/security/compute/etc.

**Description**
Clear description of the issue

**Steps to Reproduce**
1. Step one
2. Step two
3. Step three

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Error Messages**
```
terraform error output here
```

**Additional Context**
Any other relevant information
```

### Feature Requests

```markdown
**Feature Description**
Clear description of the proposed feature

**Use Case**
Why is this feature needed?

**Proposed Solution**
How should this be implemented?

**Alternatives Considered**
Other approaches considered

**Additional Context**
Any other relevant information
```

## Security Considerations

### Sensitive Information

- **Never commit**: Passwords, keys, secrets, or credentials
- **Use Key Vault**: Store all sensitive data in Azure Key Vault
- **Use data sources**: Reference secrets through data sources
- **Environment variables**: Use for authentication during development

### Network Security

- **No public IPs**: VMs should not have public IP addresses
- **Private endpoints**: Use private endpoints for all PaaS services
- **Firewall rules**: All traffic must flow through Azure Firewall
- **No NSGs**: Network Security Groups are not used in this architecture

### Access Control

- **Managed identities**: Use system-assigned managed identities where possible
- **RBAC**: Implement role-based access control
- **Least privilege**: Grant minimum required permissions
- **Regular reviews**: Review and audit access permissions

## Documentation Standards

### Module Documentation

Each module must include:

```markdown
# Module Name

## Description
Brief description of the module purpose

## Usage
```hcl
module "example" {
  source = "./modules/module-name"
  
  # Required variables
  variable1 = "value1"
  variable2 = "value2"
}
```

## Requirements
| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| azurerm | ~> 3.0 |

## Providers
| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |

## Resources
| Name | Type |
|------|------|
| resource_name | azurerm_resource_type |

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| input1 | Description | `string` | n/a | yes |

## Outputs
| Name | Description |
|------|-------------|
| output1 | Description |
```

### Code Comments

```hcl
# Create hub virtual network for shared services
# This network hosts Azure Firewall, Bastion, and Key Vault
resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.hub_address_space
  tags                = var.tags
}
```

## Getting Help

### Communication Channels

- **Issues**: GitHub issues for bugs and feature requests
- **Discussions**: GitHub discussions for questions and ideas
- **Wiki**: Project wiki for detailed documentation

### Resources

- [Azure Documentation](https://docs.microsoft.com/en-us/azure/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)

## License

By contributing to this project, you agree that your contributions will be licensed under the same license as the project.

## Recognition

Contributors will be recognized in the project documentation and release notes. Significant contributions may be highlighted in team communications and performance reviews.

---

Thank you for contributing to the TRL Hub and Spoke Azure Infrastructure project! Your contributions help improve our infrastructure capabilities and support other people's cloud journey.
