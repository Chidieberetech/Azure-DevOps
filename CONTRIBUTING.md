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
