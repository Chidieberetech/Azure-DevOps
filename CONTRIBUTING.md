# Contributing to TRL Hub-Spoke Infrastructure

Thank you for your interest in contributing to the TRL Hub-Spoke Azure infrastructure project! This guide outlines the processes and standards for contributing to our comprehensive Infrastructure as Code (IaC) implementation that covers **all 15 major Azure service categories**.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Azure Service Categories](#azure-service-categories)
- [Development Workflow](#development-workflow)
- [Naming Conventions](#naming-conventions)
- [Module Development Guidelines](#module-development-guidelines)
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
   git clone https://github.com/Chidieberetech/Azure-DevOps.git
   cd Azure-DevOps
   git checkout main   
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

## Azure Service Categories

Our infrastructure now supports **all major Azure service categories**. When contributing, please ensure your changes align with the appropriate service category:

### 🤖 AI + Machine Learning (`ai-ml.tf`)
- Cognitive Services, Machine Learning Workspace, Application Insights
- **Variables prefix**: `enable_cognitive_services`, `enable_machine_learning`
- **Naming prefix**: `cog-`, `mlw-`, `appi-`

### 📊 Analytics (`analytics.tf`)
- Synapse Analytics, Data Factory, Event Hub, Stream Analytics
- **Variables prefix**: `enable_synapse_analytics`, `enable_data_factory`
- **Naming prefix**: `synw-`, `adf-`, `evhns-`, `asa-`

### 🐳 Containers (`containers.tf`)
- AKS, Container Registry, Container Instances
- **Variables prefix**: `enable_aks`, `enable_container_registry`
- **Naming prefix**: `aks-`, `acr`, `ci-`

### 🔧 DevOps (`devops.tf`)
- DevOps tooling, artifacts storage, configuration management
- **Variables prefix**: `enable_devops`
- **Naming prefix**: `acr`, `st`, `kv-`, `appcs-`

### ⚙️ General Services (`general.tf`)
- Logic Apps, Automation, API Management, Service Bus
- **Variables prefix**: `enable_logic_apps`, `enable_automation`
- **Naming prefix**: `logic-`, `aa-`, `apim-`, `sb-`

### 🌐 Hybrid + Multicloud (`hybrid-multicloud.tf`)
- Azure Arc, Site Recovery, Migration Services, Gateways
- **Variables prefix**: `enable_arc_kubernetes`, `enable_site_recovery`
- **Naming prefix**: `arck8s-`, `rsv-`, `dms-`, `vgw-`

### 🔐 Identity (`identity.tf`)
- Azure AD Domain Services, Managed Identity, B2C
- **Variables prefix**: `enable_aad_ds`, `enable_managed_identity`
- **Naming prefix**: `aadds-`, `id-`, `kv-`

### 🔗 Integration (`integration.tf`)
- Service Bus, Event Grid, Logic Apps, Application Gateway
- **Variables prefix**: `enable_integration_servicebus`, `enable_event_grid`
- **Naming prefix**: `sb-`, `evgt-`, `logic-`, `agw-`

### 🌐 IoT (`iot.tf`)
- IoT Hub, Digital Twins, Time Series Insights, Maps
- **Variables prefix**: `enable_iot_hub`, `enable_digital_twins`
- **Naming prefix**: `iot-`, `dt-`, `tsi-`, `map-`

### 📋 Management & Governance (`management-governance.tf`)
- Policy, Management Groups, Cost Management, Advisor
- **Variables prefix**: `enable_policy`, `enable_management_group`
- **Naming prefix**: `policy-`, `mg-`, `bp-`

### 📦 Migration (`migration.tf`)
- Azure Migrate, Database Migration, Data Box, Site Recovery
- **Variables prefix**: `enable_migrate_project`, `enable_database_migration_service`
- **Naming prefix**: `migr-`, `dms-`, `rsv-`

### 🥽 Mixed Reality (`mixed-reality.tf`)
- Spatial Anchors, Remote Rendering, Object Anchors
- **Variables prefix**: `enable_spatial_anchors`, `enable_remote_rendering`
- **Naming prefix**: `spa-`, `rra-`, `oa-`

### 📈 Monitor (`monitor.tf`)
- Application Insights, Monitor, Action Groups, Workbooks
- **Variables prefix**: `enable_app_insights`, `enable_action_groups`
- **Naming prefix**: `appi-`, `ag-`, `wb-`, `ampls-`

### 🌐 Web & Mobile (`web-mobile.tf`)
- App Service, Function Apps, Static Web Apps, CDN, Front Door
- **Variables prefix**: `enable_app_service`, `enable_function_app`
- **Naming prefix**: `asp-`, `app-`, `func-`, `stapp-`, `fd-`

## Development Workflow

### Branch Strategy

We follow a **GitFlow-inspired** workflow with the following branches:

- **`main`**: Production-ready code
- **`develop`**: Integration branch for features
- **`feature/*`**: Individual feature development
- **`hotfix/*`**: Critical production fixes
- **`release/*`**: Release preparation

### Workflow Steps

1. **Create Feature Branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/service-category-new-feature
   ```

2. **Development Process**
   - Make changes in appropriate service category modules
   - Follow naming conventions and security guidelines
   - Test changes locally
   - Commit with conventional commit messages

3. **Testing and Validation**
   ```bash
   # Format code
   terraform fmt -recursive
   
   # Validate configuration
   terraform validate
   
   # Plan infrastructure
   terraform plan
   
   # Security scan
   checkov -d . --framework terraform
   ```

4. **Create Pull Request**
   - Push feature branch to remote
   - Create PR from feature branch to develop
   - Fill out PR template completely
   - Request review from maintainers

5. **Code Review Process**
   - Automated CI/CD checks must pass
   - At least one maintainer approval required
   - Security review for new services
   - Documentation review for changes

6. **Merge and Deploy**
   - Squash and merge to develop
   - Delete feature branch
   - Deploy to development environment for testing

### Release Process

1. **Create Release Branch**
   ```bash
   git checkout develop
   git checkout -b release/v1.x.x
   ```

2. **Prepare Release**
   - Update version numbers
   - Update CHANGELOG.md
   - Final testing and validation
   - Update documentation

3. **Release to Production**
   - Merge release branch to main
   - Tag release with version number
   - Deploy to production environment
   - Merge back to develop

### Hotfix Process

For critical production issues:

1. **Create Hotfix Branch**
   ```bash
   git checkout main
   git checkout -b hotfix/critical-issue-description
   ```

2. **Fix and Test**
   - Make minimal necessary changes
   - Test thoroughly
   - Update version number

3. **Deploy Hotfix**
   - Merge to main and develop
   - Tag new version
   - Deploy immediately to production

## Naming Conventions

### Git Branch Naming

- **Feature branches**: `feature/service-category-description`
  - Examples: `feature/containers-add-aks-support`, `feature/ai-ml-cognitive-services`
- **Hotfix branches**: `hotfix/issue-description`
  - Examples: `hotfix/storage-private-endpoint-fix`
- **Release branches**: `release/v1.2.3`

### Commit Message Conventions

Follow **Conventional Commits** specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Commit Types

- **feat**: New feature or service addition
- **fix**: Bug fix or configuration correction
- **docs**: Documentation changes
- **style**: Code formatting (no logic changes)
- **refactor**: Code restructuring (no functionality change)
- **test**: Adding or modifying tests
- **chore**: Maintenance tasks, dependency updates

#### Scope Examples

Use service category names as scopes:
- `ai-ml`: AI and Machine Learning services
- `containers`: Container services
- `networking`: Network infrastructure
- `security`: Security-related changes
- `storage`: Storage services
- `database`: Database services

#### Commit Message Examples

```bash
# Good examples
git commit -m "feat(containers): add Azure Container Apps support"
git commit -m "fix(ai-ml): correct Cognitive Services private endpoint configuration"
git commit -m "docs(readme): update service category coverage"
git commit -m "refactor(networking): simplify subnet naming logic"
git commit -m "chore(deps): update azurerm provider to v3.75.0"

# Bad examples
git commit -m "fixed stuff"
git commit -m "Update files"
git commit -m "Added new service"
```

### Azure Resource Naming

All Azure resources must follow the **TRL standardized naming convention**:

#### Pattern
```
{resource-type}-{ENV}-{LOCATION}-{purpose}-{instance}
```

#### Components

- **Resource Type**: Use standard Azure abbreviations (see README.md tables)
- **Environment**: `DEV`, `STG`, `PRD`
- **Location**: `WEU` (West Europe), `EUS` (East US), etc.
- **Purpose**: Service category or specific function
- **Instance**: 3-digit number with leading zeros

#### Examples by Service Category

```bash
# AI + Machine Learning
"cog-PRD-WEU-vision-001"     # Cognitive Services
"mlw-PRD-WEU-training-001"   # ML Workspace

# Containers
"aks-PRD-WEU-workload-001"   # Kubernetes Service
"acr${env}${location}${random}" # Container Registry (no hyphens)

# Networking
"vnet-PRD-WEU-hub-001"       # Virtual Network
"snet-PRD-WEU-alpha-vm-001"  # Subnet

# Storage
"st${env}${location}${random}" # Storage Account (no hyphens)
"kv-PRD-WEU-secrets-001"     # Key Vault

# Web & Mobile
"asp-PRD-WEU-webapp-001"     # App Service Plan
"func-PRD-WEU-functions-001" # Function App

# Database
"sql-PRD-WEU-appdb-001"      # SQL Database
"cosmos-PRD-WEU-nosql-001"   # Cosmos DB

# General Services
"apim-PRD-WEU-api-001"       # API Management
"sb-PRD-WEU-messaging-001"   # Service Bus

# Identity
"aadds-PRD-WEU-domain-001"    # Azure AD Domain Services
"id-PRD-WEU-identity-001"     # Managed Identity

# IoT
"iot-PRD-WEU-hub-001"         # IoT Hub
"dt-PRD-WEU-twins-001"        # Digital Twins

# Monitor
"appi-PRD-WEU-insights-001"   # Application Insights
"ag-PRD-WEU-alerts-001"       # Action Group

# Analytics
"synw-PRD-WEU-analytics-001"  # Synapse Workspace
"adf-PRD-WEU-datafactory-001" # Data Factory
"evhns-PRD-WEU-eventhub-001"  # Event Hub Namespace
"asa-PRD-WEU-stream-001"      # Stream Analytics Job

# Migration
"migr-PRD-WEU-assessment-001" # Migrate Project
"dms-PRD-WEU-dbmigration-001"  # Database Migration Service

# Mixed Reality
"spa-PRD-WEU-anchors-001"     # Spatial Anchors
"rra-PRD-WEU-rendering-001"   # Remote Rendering
"oa-PRD-WEU-object-001"       # Object Anchors

# Hybrid + Multicloud
"arck8s-PRD-WEU-arc-001"      # Azure Arc
"rsv-PRD-WEU-recovery-001"    # Site Recovery
"dms-PRD-WEU-migration-001"   # Data Migration Service
"vgw-PRD-WEU-gateway-001"     # Virtual Gateway

# DevOps
"acr${env}${location}${random}" # Azure Container Registry (no hyphens)
"st${env}${location}${random}"  # Storage Account (no hyphens)
"kv-PRD-WEU-secrets-001"      # Key Vault
"appcs-PRD-WEU-appconfig-001" # App Configuration
  
# Management & Governance
"policy-PRD-WEU-compliance-001" # Policy Assignment
"mg-PRD-WEU-management-001"     # Management Group
"bp-PRD-WEU-budget-001"         # Budget
  
# Security
"nsg-PRD-WEU-web-001"          # Network Security Group
"fw-PRD-WEU-firewall-001"      # Firewall
"waf-PRD-WEU-waf-001"          # Web Application Firewall
"ddos-PRD-WEU-protection-001"  # DDoS Protection Plan
  
# Integration
"sb-PRD-WEU-messaging-001"     # Service Bus
"evgt-PRD-WEU-events-001"      # Event Grid Topic
"logic-PRD-WEU-workflow-001"   # Logic App
"agw-PRD-WEU-gateway-001"      # Application Gateway
```

### Variable Naming

#### Enabling Services
```hcl
# Pattern: enable_{service_category}_{specific_service}
enable_cognitive_services = true
enable_machine_learning = false
enable_aks = true
enable_container_registry = false
```

#### Service Configuration
```hcl
# Pattern: {service}_{configuration_type}
cognitive_services_sku = "S0"
aks_node_count = 3
container_registry_sku = "Premium"
app_service_sku = "B1"
```

#### Service-Specific Settings
```hcl
# Pattern: {service}_{specific_setting}
aks_vm_size = "Standard_D2s_v3"
api_management_publisher_name = "TRL Organization"
storage_replication_type = "LRS"
```

### File Naming

#### Terraform Files
- Use lowercase with hyphens for multi-word names
- Group by service category
- Examples: `ai-ml.tf`, `containers.tf`, `web-mobile.tf`

#### Documentation Files
- Use UPPERCASE for main documentation
- Use hyphens for multi-word names
- Examples: `README.md`, `CONTRIBUTING.md`, `PROJECT-STRUCTURE.md`

#### Script Files
- Use lowercase with hyphens
- Include purpose in name
- Examples: `vm-password-rotation.sh`, `cost-analysis.sh`

### Output Naming

```hcl
# Pattern: {service_category}_{resource_type}_{property}
output "containers_aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = var.enable_aks ? azurerm_kubernetes_cluster.main[0].id : null
}

output "ai_ml_cognitive_services_endpoint" {
  description = "Endpoint URL for Cognitive Services"
  value       = var.enable_cognitive_services ? azurerm_cognitive_account.main[0].endpoint : null
}
```

### Local Values Naming

```hcl
# Use descriptive names for computed values
locals {
  resource_prefix = "${local.env_abbr[var.environment]}-${local.location_abbr[var.location]}"
  
  common_tags = {
    Environment = var.environment
    Project     = "Azure.IAC.hubspoke"
    ManagedBy   = "Terraform"
    Owner       = "TRL"
  }
  
  # Service-specific locals
  aks_dns_prefix = "aks-${local.resource_prefix}"
  storage_account_name = "st${lower(local.env_abbr[var.environment])}${lower(local.location_abbr[var.location])}${random_string.suffix.result}"
}
```

## Module Development Guidelines

### Adding New Azure Services

When adding new Azure services to existing modules:

1. **Follow the existing pattern**:
   ```hcl
   # Service Resource
   resource "azurerm_service_name" "main" {
     count               = var.enable_service_name ? 1 : 0
     name                = "prefix-${local.resource_prefix}-${format("%03d", 1)}"
     location            = azurerm_resource_group.spokes[0].location
     resource_group_name = azurerm_resource_group.spokes[0].name
     
     # Security settings
     public_network_access_enabled = false
     
     tags = local.common_tags
   }

   # Private Endpoint
   resource "azurerm_private_endpoint" "service_name" {
     count               = var.enable_service_name ? 1 : 0
     name                = "pep-${local.resource_prefix}-service-${format("%03d", 1)}"
     location            = azurerm_resource_group.spokes[0].location
     resource_group_name = azurerm_resource_group.spokes[0].name
     subnet_id           = azurerm_subnet.spoke_alpha_private_endpoint[0].id

     private_service_connection {
       name                           = "psc-service-name"
       private_connection_resource_id = azurerm_service_name.main[0].id
       subresource_names              = ["subresource"]
       is_manual_connection           = false
     }

     tags = local.common_tags
   }
   ```

2. **Add corresponding variables** in `variables.tf`:
   ```hcl
   variable "enable_service_name" {
     description = "Enable Azure Service Name"
     type        = bool
     default     = false
   }

   variable "service_name_sku" {
     description = "SKU for Azure Service Name"
     type        = string
     default     = "Standard"
   }
   ```

3. **Add outputs** in `outputs.tf`:
   ```hcl
   output "service_name_id" {
     description = "ID of the Azure Service Name"
     value       = var.enable_service_name ? azurerm_service_name.main[0].id : null
   }
   ```

### Security Requirements

All new services must implement:

1. **Private Connectivity**: Use private endpoints where available
2. **Network Isolation**: Deploy in appropriate subnets
3. **Identity Management**: Use managed identities for authentication
4. **Encryption**: Enable encryption at rest and in transit
5. **Access Control**: Implement the least privilege access

### Naming Convention Compliance

All resources must follow the TRL naming convention:
- **Pattern**: `{resource-type}-{ENV}-{LOCATION}-{purpose}-{instance}`
- **Environment**: Use `local.env_abbr[var.environment]`
- **Location**: Use `local.location_abbr[var.location]`
- **Instance**: Use `format("%03d", 1)` for consistent numbering

## Testing Requirements

### Pre-commit Testing

Before submitting changes:

1. **Terraform validation**:
   ```bash
   terraform fmt -recursive
   terraform validate
   ```

2. **Security scanning**:
   ```bash
   # Use checkov or similar tool
   checkov -f main.tf --framework terraform
   ```

3. **Cost estimation**:
   ```bash
   # Use Infracost or similar tool
   infracost breakdown --path .
   ```

### Integration Testing

1. **Plan verification**: Ensure `terraform plan` succeeds
2. **Resource validation**: Verify resources are created correctly
3. **Connectivity testing**: Test private endpoint connectivity
4. **Security validation**: Confirm security configurations

## Pull Request Process

### Before Creating a PR

1. **Create feature branch**:
   ```bash
   git checkout -b feature/add-azure-service-name
   ```

2. **Follow conventional commits**:
   ```bash
   git commit -m "feat(containers): add Azure Container Apps support"
   git commit -m "fix(ai-ml): correct Cognitive Services SKU validation"
   git commit -m "docs(readme): update service category coverage"
   ```

### PR Requirements

- [ ] **Service Category**: Clearly identify which service category is affected
- [ ] **Variable Documentation**: Document all new variables
- [ ] **Security Review**: Confirm security best practices
- [ ] **Testing**: Include test results and validation
- [ ] **Documentation**: Update relevant .md files
- [ ] **Breaking Changes**: Clearly document any breaking changes

### PR Template

Use this template for all pull requests:

```markdown
## Service Category
<!-- Check applicable category -->
- [ ] 🤖 AI + Machine Learning
- [ ] 📊 Analytics  
- [ ] 🐳 Containers
- [ ] 🔧 DevOps
- [ ] ⚙️ General Services
- [ ] 🌐 Hybrid + Multicloud
- [ ] 🔐 Identity
- [ ] 🔗 Integration
- [ ] 🌐 IoT
- [ ] 📋 Management & Governance
- [ ] 📦 Migration
- [ ] 🥽 Mixed Reality
- [ ] 📈 Monitor
- [ ] 🌐 Web & Mobile

## Description
<!-- Describe the changes made -->

## Testing
<!-- Include test results, validation outputs -->

## Security Considerations
<!-- Document security implications -->

## Breaking Changes
<!-- List any breaking changes -->
```

## Documentation Standards

### Module Documentation

Each service module must include:
- **Purpose**: What the module does
- **Services Included**: List of Azure services
- **Variables**: Documentation of all input variables
- **Outputs**: Documentation of all outputs
- **Examples**: Usage examples

### README Updates

When adding new services, update:
- Main `README.md`: Add service to category list
- `PROJECT-STRUCTURE.md`: Update module structure
- Service-specific documentation as needed

## Security Guidelines

### Mandatory Security Practices

1. **Private Endpoints**: Always use private endpoints for PaaS services
2. **Network Security**: Deploy services in appropriate subnets
3. **Identity Management**: Use managed identities over service principals
4. **Key Management**: Store secrets in Key Vault
5. **Encryption**: Enable encryption for all data storage

### Security Review Checklist

- [ ] Private endpoints configured where available
- [ ] No hardcoded secrets or credentials
- [ ] Managed identities used for service authentication
- [ ] Network security groups properly configured
- [ ] Encryption enabled for data at rest and in transit
- [ ] Least privilege access principles applied

## Code Quality Standards

### Terraform Best Practices

- Use consistent formatting (`terraform fmt`)
- Validate all configurations (`terraform validate`)
- Use meaningful variable names and descriptions
- Implement proper resource dependencies
- Use locals for computed values and naming

### Variable Naming

- Use descriptive names: `enable_cognitive_services` not `enable_cs`
- Group related variables: All IoT variables together
- Use consistent prefixes: `enable_*`, `*_sku`, `*_capacity`

By following these guidelines, we ensure our infrastructure remains secure, maintainable, and aligned with Azure best practices across all service categories.
