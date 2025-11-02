# Contributing to Azure Hub-Spoke Infrastructure

Thank you for your interest in contributing to the Azure Hub-Spoke Infrastructure as Code (IaC) project! This document provides guidelines and best practices for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Documentation Standards](#documentation-standards)

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Prioritize security and best practices

## Getting Started

### Prerequisites

Before contributing, ensure you have the following installed:

- **Terraform** v1.13.4 (exact version required)
- **Azure CLI** (latest version)
- **Git** for version control
- **PowerShell** (for Windows environments)
- **Bash** (for script execution)

### Initial Setup

1. **Fork the repository** to your GitHub account
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/Azure.IAC.hubspoke.git
   cd Azure.IAC.hubspoke
   ```

3. **Add the upstream remote**:
   ```bash
   git remote add upstream https://github.com/original-repo/Azure.IAC.hubspoke.git
   ```

4. **Set up your Azure credentials**:
   - Configure Azure CLI: `az login`
   - Set appropriate subscription: `az account set --subscription <subscription-id>`

5. **Review the project documentation**:
   - README.md
   - PIPELINE-SETUP-GUIDE.md
   - PIPELINE-VARIABLES-GUIDE.md
   - PIPELINE-DEPLOYMENT-GUIDE.md

## Development Workflow

### Branch Strategy

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features and enhancements
- `fix/*` - Bug fixes
- `hotfix/*` - Critical production fixes

### Creating a New Feature

1. **Update your local repository**:
   ```bash
   git checkout main
   git pull upstream main
   ```

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes** following the coding standards

4. **Test your changes** thoroughly (see Testing Guidelines)

5. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: descriptive commit message"
   ```

6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request** from your fork to the upstream repository

## Project Structure

```
Azure.IAC.hubspoke/
├── modules/              # Reusable Terraform modules
│   ├── main.tf          # Core infrastructure resources
│   ├── variables.tf     # Module input variables
│   ├── network.tf       # Hub and spoke network configuration
│   ├── compute.tf       # Virtual machines and compute resources
│   ├── storage.tf       # Storage accounts and data lakes
│   ├── database.tf      # Database services (SQL, Cosmos DB)
│   ├── security.tf      # Security resources (Key Vault, etc.)
│   ├── monitor.tf       # Monitoring and alerting
│   ├── keyvault.tf      # Key Vault configuration
│   ├── analytics.tf     # Analytics services
│   ├── containers.tf    # Container services (AKS, ACI)
│   ├── devops.tf        # DevOps resources
│   ├── ai-ml.tf         # AI/ML services
│   └── ...
├── workspaces/          # Environment-specific configurations
│   ├── hub/             # Hub workspace (shared services)
│   ├── management/      # Management workspace
│   └── spokes/          # Spoke workspaces (dev, int, prod)
├── pipelines/           # Azure DevOps pipeline definitions
│   ├── Subscription pipeline/
│   ├── Destroy/
│   └── Azure/
├── scripts/             # Automation and utility scripts
└── docs/               # Additional documentation
```

## Coding Standards

### Terraform Best Practices

#### 1. **File Organization**
- Group related resources in separate files (e.g., `network.tf`, `compute.tf`)
- Keep `variables.tf` and `outputs.tf` organized alphabetically
- Use `locals.tf` for computed values and constants

#### 2. **Naming Conventions**

**Resources:**
```terraform
# Format: <resource-type>-<project>-<environment>-<name>-<instance>
resource "azurerm_resource_group" "hub" {
  name     = "rg-trl-${local.environment_abbr}-hub-001"
  location = var.location
  tags     = local.common_tags
}
```

**Variables:**
```terraform
# Use descriptive names with underscores
variable "enable_firewall" {
  description = "Enable Azure Firewall"
  type        = bool
  default     = false
}
```

**Locals:**
```terraform
# Use descriptive names for computed values
locals {
  resource_prefix = "trl-${local.environment_abbr}"
  hub_resource_group_name = "rg-trl-${local.environment_abbr}-hub-001"
}
```

#### 3. **Resource Naming Standards**

Follow Azure naming conventions:
- **Resource Groups**: `rg-<project>-<env>-<name>-<instance>`
- **Virtual Networks**: `vnet-<project>-<env>-<name>-<instance>`
- **Subnets**: `snet-<project>-<env>-<name>-<instance>`
- **Storage Accounts**: `st<env><location><random>` (lowercase, no hyphens)
- **Key Vaults**: `kv-<project>-<env>-<random>`
- **VMs**: `vm-<project>-<env>-<name>-<instance>`
- **Log Analytics**: `law-<project>-<env>-<instance>`

#### 4. **Code Formatting**
- Run `terraform fmt -recursive` before committing
- Use consistent indentation (2 spaces)
- Add blank lines between resource blocks
- Group related attributes together

#### 5. **Documentation**
```terraform
# Add comments for complex logic
# Describe why, not what (code shows what)

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_B1s"
  
  validation {
    condition     = can(regex("^Standard_", var.vm_size))
    error_message = "VM size must be a Standard SKU."
  }
}
```

#### 6. **Variable Definitions**
- Always include `description`
- Specify `type` explicitly
- Use `validation` blocks where appropriate
- Mark sensitive variables with `sensitive = true`
- Provide sensible `default` values when applicable

#### 7. **Tags**
- Use consistent tagging strategy
- Include: Environment, Project, ManagedBy, Owner
- Apply tags through `local.common_tags`

```terraform
locals {
  common_tags = merge({
    Environment = var.environment
    Project     = "Azure.IAC.hubspoke"
    ManagedBy   = "Terraform"
    Owner       = var.owner_email
  }, var.additional_tags)
}
```

#### 8. **State Management**
- Always use remote state (Azure Storage)
- Never commit `.tfstate` files
- Use state locking to prevent conflicts

#### 9. **Security Best Practices**
- Never hardcode secrets or passwords
- Use Azure Key Vault for sensitive data
- Enable soft delete on Key Vault resources
- Implement network security groups
- Use private endpoints where possible
- Enable encryption at rest and in transit

### Shell Script Standards

#### Bash Scripts
```bash
#!/bin/bash
# Script description and purpose

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Use descriptive variable names
ENVIRONMENT="${1:-dev}"
WORKSPACE_PATH="./workspaces/${ENVIRONMENT}"

# Add error handling
if [ ! -d "${WORKSPACE_PATH}" ]; then
    echo "Error: Workspace directory not found"
    exit 1
fi

# Add helpful output
echo "Deploying to ${ENVIRONMENT} environment..."
```

#### PowerShell Scripts
```powershell
#!/usr/bin/env pwsh
# Script description and purpose

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"

# Use approved verbs
# Add error handling
# Include Write-Verbose statements
```

### YAML Pipeline Standards

```yaml
# Include descriptive comments
# Use variables for reusability
# Organize stages logically
# Include proper error handling

variables:
  - name: environmentName
    value: 'dev'
  - name: terraformVersion
    value: '1.13.4'

stages:
  - stage: Plan
    displayName: 'Terraform Plan'
    jobs:
      - job: TerraformPlan
        displayName: 'Run Terraform Plan'
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: $(terraformVersion)
```

## Testing Guidelines

### Pre-Commit Checks

Before committing, run these checks:

1. **Format Check**:
   ```bash
   terraform fmt -check -recursive
   ```

2. **Validation**:
   ```bash
   cd workspaces/hub
   terraform init
   terraform validate
   ```

3. **Linting** (if using tflint):
   ```bash
   tflint --recursive
   ```

### Testing in Non-Production

1. **Test in dev environment first**
2. **Use terraform plan** to review changes
3. **Apply changes incrementally**
4. **Verify resources in Azure Portal**
5. **Test functionality** of deployed resources
6. **Check monitoring and alerts**

### Test Checklist

- [ ] Terraform fmt applied
- [ ] Terraform validate passes
- [ ] No hardcoded values
- [ ] Variables have descriptions
- [ ] Tags are applied
- [ ] Resources follow naming conventions
- [ ] Documentation updated
- [ ] Tested in dev environment
- [ ] No security vulnerabilities introduced

## Pull Request Process

### Before Submitting

1. **Update from upstream**:
   ```bash
   git checkout main
   git pull upstream main
   git checkout feature/your-feature-name
   git rebase main
   ```

2. **Run all tests and validations**

3. **Update documentation** if needed

4. **Write clear commit messages**

### Commit Message Format

Use conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(network): add support for Azure Firewall Premium

- Implemented Azure Firewall Premium SKU option
- Added DNS proxy configuration
- Updated documentation

Closes #123
```

```
fix(storage): correct storage account network rules race condition

Applied network rules separately from storage account creation
to avoid service endpoint race condition.

Fixes #456
```

### Pull Request Template

When creating a PR, include:

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested in dev environment
- [ ] Terraform validate passes
- [ ] All resources created successfully
- [ ] No security issues introduced

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Dependent changes merged

## Related Issues
Fixes #(issue number)
```

### Review Process

1. **Automated checks** must pass
2. **At least one approval** required
3. **All comments** must be resolved
4. **Up to date** with main branch
5. **Documentation** must be current

## Documentation Standards

### When to Update Documentation

Update documentation when you:
- Add new features or modules
- Change variable names or types
- Modify resource configurations
- Add new workspaces or environments
- Change deployment procedures
- Fix bugs that affect usage

### Documentation Files to Update

- **README.md**: High-level overview and quick start
- **CONTRIBUTING.md**: This file (contribution guidelines)
- **PIPELINE-SETUP-GUIDE.md**: Pipeline configuration steps
- **PIPELINE-VARIABLES-GUIDE.md**: Variable definitions and usage
- **PIPELINE-DEPLOYMENT-GUIDE.md**: Deployment procedures
- **Module-specific docs**: For individual workspace changes
- **VARIABLES-SUMMARY.md**: When adding/changing variables

### Documentation Style

- Use clear, concise language
- Include code examples
- Add screenshots for UI-based steps
- Keep table of contents updated
- Use proper markdown formatting
- Include links to related documentation

### Code Comments

```terraform
# Good comment: Explains WHY
# Firewall subnet requires specific name for Azure to recognize it
resource "azurerm_subnet" "firewall" {
  name = "AzureFirewallSubnet"
  # ...
  address_prefixes = []
  resource_group_name  = ""
  virtual_network_name = ""
}

# Bad comment: Explains WHAT (code is self-explanatory)
# Create a subnet
resource "azurerm_subnet" "firewall" {
  # ...
  address_prefixes = []
  name                 = ""
  resource_group_name  = ""
  virtual_network_name = ""
}
```

## Getting Help

If you need help:

1. **Check existing documentation** in the repository
2. **Search closed issues** for similar problems
3. **Open a new issue** with detailed information
4. **Contact maintainers** for guidance

## Release Process

Releases follow semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing to the Azure Hub-Spoke Infrastructure project!

