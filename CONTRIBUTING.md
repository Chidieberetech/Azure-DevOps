# Contributing to TRL Hub-Spoke Infrastructure

Thank you for your interest in contributing to the TRL Hub-Spoke Azure infrastructure project! This guide outlines the processes and standards for contributing to our Infrastructure as Code (IaC) implementation.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Naming Conventions](#naming-conventions)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Documentation Standards](#documentation-standards)
- [Security Guidelines](#security-guidelines)

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please read and follow our Code of Conduct in all interactions.

## Getting Started

### Prerequisites

Before contributing, ensure you have the following tools installed:

- **Terraform** (>= 1.5.0)
- **Azure CLI** (>= 2.50.0)
- **Git** (>= 2.30.0)
- **Visual Studio Code** (recommended) with extensions:
  - HashiCorp Terraform
  - Azure Tools
  - GitLens

### Development Environment Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/trl/azure-hubspoke-infrastructure.git
   cd azure-hubspoke-infrastructure
   ```

2. **Set up Azure authentication**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

3. **Initialize Terraform**
   ```bash
   cd workspaces/hub
   terraform init
   ```

## Development Workflow

### Branch Strategy

We follow the GitFlow branching model:

- **main**: Production-ready code
- **develop**: Integration branch for features
- **feature/***: Individual feature development
- **hotfix/***: Critical fixes for production
- **release/***: Preparation for new releases

### Feature Development Process

1. **Create a feature branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow naming conventions
   - Update documentation
   - Add tests where applicable

3. **Test your changes**
   ```bash
   terraform fmt -recursive
   terraform validate
   terraform plan
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

5. **Push and create pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Naming Conventions

### Azure Resource Naming

All resources must follow the standardized naming pattern:
`{resource-type}-{ENV}-{LOCATION}-{purpose}-{instance}`

#### Examples:
- **Virtual Machines**: `vm-PRD-WEU-alpha-001`, `vm-DEV-WEU-beta-001`
- **Virtual Networks**: `vnet-PRD-WEU-hub-001`, `vnet-STG-WEU-alpha-001`
- **Resource Groups**: `rg-trl-PRD-alpha-001`, `RG-TRL-Hub-weu`
- **Storage Accounts**: `stprdweu001`, `stdeveus002`
- **Key Vaults**: `kv-PRD-WEU-001`, `kv-STG-WEU-001`
- **Network Security Groups**: `nsg-PRD-WEU-hub-001`
- **Subnets**: `snet-PRD-WEU-alpha-vm-001`
- **Azure Firewall**: `afw-PRD-WEU-001`
- **SQL Server**: `sql-PRD-WEU-001`

#### Environment Abbreviations:
- **PRD**: Production
- **STG**: Staging
- **DEV**: Development

#### Location Abbreviations:
- **WEU**: West Europe
- **EUS**: East US
- **NEU**: North Europe
- **CUS**: Central US

### Terraform Naming Conventions

#### Resource Names
```hcl
# Good
resource "azurerm_virtual_network" "hub" {
  name = "vnet-${local.resource_prefix}-hub-${format("%03d", 1)}"
}

# Bad
resource "azurerm_virtual_network" "vnet1" {
  name = "my-vnet"
}
```

#### Variable Names
```hcl
# Good
variable "spoke_count" {
  description = "Number of spoke networks to create"
  type        = number
  default     = 2
}

# Bad
variable "count" {
  type = number
}
```

#### Local Values
```hcl
# Good
locals {
  env_abbr = {
    dev     = "DEV"
    staging = "STG"
    prod    = "PRD"
  }
  
  spoke_names = ["alpha", "beta", "gamma"]
}
```

## Testing Requirements

### Pre-commit Checks

Before committing code, ensure the following passes:

1. **Terraform Formatting**
   ```bash
   terraform fmt -recursive -check
   ```

2. **Terraform Validation**
   ```bash
   terraform validate
   ```

3. **Security Scanning**
   ```bash
   # Using tfsec (if available)
   tfsec .
   ```

4. **Documentation Generation**
   ```bash
   # Using terraform-docs (if available)
   terraform-docs markdown table --output-file README.md .
   ```

### Testing Strategy

#### Unit Testing
- **Module Testing**: Each module should be testable in isolation
- **Variable Validation**: All variables should have appropriate validation rules
- **Output Verification**: Outputs should be meaningful and well-documented

#### Integration Testing
- **Pipeline Testing**: Changes should pass through CI/CD pipelines
- **Environment Testing**: Test in development environment before production
- **Security Testing**: Security configurations should be validated

#### Example Test Structure
```hcl
# In modules/variables.tf
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vm_size" {
  description = "Size of the virtual machines"
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

## Pull Request Process

### PR Requirements

1. **Descriptive Title**: Use conventional commit format
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `refactor:` for code refactoring
   - `test:` for adding tests

2. **Detailed Description**: Include:
   - What changes were made
   - Why the changes were necessary
   - How to test the changes
   - Any breaking changes

3. **Checklist**: Ensure all items are completed:
   - [ ] Code follows naming conventions
   - [ ] Documentation updated
   - [ ] Tests added/updated
   - [ ] Security implications considered
   - [ ] Terraform fmt and validate pass
   - [ ] No sensitive data in code

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Terraform validate passes
- [ ] Terraform plan reviewed
- [ ] Security scan completed
- [ ] Manual testing performed

## Checklist
- [ ] Follows naming conventions
- [ ] Documentation updated
- [ ] No sensitive data exposed
- [ ] Backward compatibility maintained
```

### Review Process

1. **Automated Checks**: PR must pass all automated checks
2. **Peer Review**: At least one team member must review
3. **Security Review**: Security-related changes need security team approval
4. **Documentation Review**: Documentation changes reviewed for accuracy

## Documentation Standards

### File Documentation

#### README Files
- Each module should have a comprehensive README.md
- Include usage examples
- Document all variables and outputs
- Provide troubleshooting guidance

#### Inline Documentation
```hcl
# Spoke Alpha Virtual Machine
# Deploys a Windows Server VM in the Alpha spoke network
# with IIS web server and proper security configuration
resource "azurerm_windows_virtual_machine" "spoke_alpha_vm" {
  count               = var.spoke_count >= 1 ? 1 : 0
  name                = "vm-${local.resource_prefix}-alpha-${format("%03d", 1)}"
  resource_group_name = azurerm_resource_group.spokes[0].name
  # ... rest of configuration
}
```

#### Architecture Documentation
- Network diagrams should be updated for infrastructure changes
- Security documentation for new security features
- Operational runbooks for new operational procedures

### Code Comments

#### Resource Comments
```hcl
# Azure Firewall for centralized network security
# Routes all spoke traffic and provides DNAT rules for external access
resource "azurerm_firewall" "main" {
  # Configuration here
}
```

#### Variable Comments
```hcl
variable "spoke_count" {
  description = "Number of spoke networks to create (max 3 for current design)"
  type        = number
  default     = 2
  
  validation {
    condition = var.spoke_count >= 0 && var.spoke_count <= 3
    error_message = "Spoke count must be between 0 and 3."
  }
}
```

## Security Guidelines

### Security Best Practices

1. **No Hardcoded Secrets**: Never commit passwords, keys, or sensitive data
2. **Use Key Vault**: Store all secrets in Azure Key Vault
3. **Principle of Least Privilege**: Assign minimal required permissions
4. **Network Security**: Implement network segmentation and firewalls
5. **Encryption**: Ensure data is encrypted at rest and in transit

### Security Code Examples

#### Secure Secret Management
```hcl
# Good - Using Key Vault reference
data "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  key_vault_id = azurerm_key_vault.main.id
}

# Bad - Hardcoded password
admin_password = "MyPassword123!"
```

#### Secure Storage Configuration
```hcl
# Good - Secure storage account
resource "azurerm_storage_account" "main" {
  # ... other configuration
  
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}
```

### Security Review Checklist

- [ ] No sensitive data in code or comments
- [ ] All secrets stored in Key Vault
- [ ] Network security properly configured
- [ ] Storage accounts secured with private endpoints
- [ ] VM access restricted to authorized users
- [ ] Monitoring and logging enabled
- [ ] Backup and recovery configured

## Infrastructure Patterns

### Spoke Architecture

When adding new spokes, follow the established pattern:

```hcl
# Spoke naming follows: alpha, beta, gamma, delta, etc.
locals {
  spoke_names = ["alpha", "beta", "gamma"]
}

# Network addressing follows sequential pattern
locals {
  spoke_alpha_address_space = ["10.1.0.0/16"]
  spoke_beta_address_space  = ["10.2.0.0/16"]
  spoke_gamma_address_space = ["10.3.0.0/16"]
}
```

### Resource Organization

- **Hub Resources**: Shared services in hub resource group
- **Spoke Resources**: Workload-specific resources in spoke resource groups
- **Management Resources**: Monitoring and governance in management resource group

## Release Process

### Version Management

We use semantic versioning (SemVer) for releases:
- **Major**: Breaking changes
- **Minor**: New features (backward compatible)
- **Patch**: Bug fixes

### Release Workflow

1. **Feature Freeze**: Complete all features for release
2. **Testing**: Comprehensive testing in staging environment
3. **Documentation**: Update all documentation
4. **Release Notes**: Document all changes
5. **Deployment**: Deploy to production
6. **Monitoring**: Monitor post-deployment

## Getting Help

### Documentation Resources
- [Project Structure](PROJECT-STRUCTURE.md)
- [Pipeline Setup Guide](PIPELINE-SETUP-GUIDE.md)
- [Azure Naming Conventions](README.md#azure-resource-naming-conventions)

### Communication Channels
- **Issues**: GitHub Issues for bug reports and feature requests
- **Discussions**: GitHub Discussions for general questions
- **Security**: security@trl.com for security-related issues

### Contact Information
- **Infrastructure Team**: infrastructure@trl.com
- **Security Team**: security@trl.com
- **Project Lead**: project-lead@trl.com

Thank you for contributing to the TRL Hub-Spoke Infrastructure project!
