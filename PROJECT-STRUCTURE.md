# TRL Hub-Spoke Infrastructure Project Structure

This document outlines the comprehensive structure and organization of the TRL Hub-Spoke Azure infrastructure project, which implements enterprise-grade naming conventions and a secure network topology.

## Project Organization

### Root Structure
```
Azure-DevOps/
├── modules/                    # Core Terraform modules
├── workspaces/                # Environment-specific configurations
├── pipelines/                 # CI/CD pipeline definitions
├── scripts/                   # Automation and utility scripts
└── documentation/             # Project documentation
```

## Azure Resource Naming Conventions

All resources follow the standardized naming pattern:
`{resource-type}-{ENV}-{LOCATION}-{purpose}-{instance}`

### Environment Abbreviations
- **PRD**: Production
- **STG**: Staging  
- **DEV**: Development

### Location Abbreviations
- **WEU**: West Europe
- **EUS**: East US
- **NEU**: North Europe
- **CUS**: Central US

### Resource Examples
- **Virtual Machines**: `vm-PRD-WEU-alpha-001`, `vm-PRD-WEU-beta-001`
- **Virtual Networks**: `vnet-PRD-WEU-hub-001`, `vnet-PRD-WEU-alpha-001`
- **Resource Groups**: `rg-trl-PRD-alpha-001`, `RG-TRL-Hub-weu`
- **Storage Accounts**: `stprdweu001`, `stdiagprdweu001`
- **Key Vaults**: `kv-PRD-WEU-001`
- **Network Security Groups**: `nsg-PRD-WEU-hub-001`
- **Subnets**: `snet-PRD-WEU-alpha-vm-001`
- **Azure Firewall**: `afw-PRD-WEU-001`
- **SQL Server**: `sql-PRD-WEU-001`

## Infrastructure Architecture

### Hub and Spoke Design
The infrastructure implements a centralized hub with dedicated spoke networks:

#### Hub (RG-TRL-Hub-weu)
- **Purpose**: Shared services and central security
- **VNet**: `vnet-PRD-WEU-hub-001` (10.0.0.0/16)
- **Key Components**:
  - Azure Firewall: `afw-PRD-WEU-001`
  - Azure Bastion: `bastion-PRD-WEU-001`
  - Key Vault: `kv-PRD-WEU-001`
  - Diagnostics Storage: `stdiagprdweu001`

#### Spoke Alpha
- **Purpose**: Primary workload environment
- **VNet**: `vnet-PRD-WEU-alpha-001` (10.1.0.0/16)
- **VM**: `vm-PRD-WEU-alpha-001` (10.1.4.10)
- **Storage**: `stprdweu001`

#### Spoke Beta
- **Purpose**: Secondary workload environment
- **VNet**: `vnet-PRD-WEU-beta-001` (10.2.0.0/16)
- **VM**: `vm-PRD-WEU-beta-001` (10.2.4.10)

## Module Structure

### `/modules/` Directory
Contains the core Terraform infrastructure modules:

#### Core Configuration Files
- **main.tf**: Resource groups and fundamental infrastructure
- **locals.tf**: Local values, naming conventions, and computed data
- **variables.tf**: Input variable definitions with validation
- **outputs.tf**: Output values for resource information
- **versions.tf**: Provider version constraints

#### Infrastructure Modules
- **network.tf**: Virtual networks, subnets, and peering
- **security.tf**: Firewall, Bastion, and network security groups
- **compute.tf**: Virtual machines, extensions, and routing
- **storage.tf**: Storage accounts, containers, and private endpoints
- **keyvault.tf**: Key Vault, secrets, and private DNS zones
- **database.tf**: SQL Server, SQL Database, and Cosmos DB

### Module Features
- **Consistent Naming**: Automated resource naming using local values
- **Environment Awareness**: Dynamic configuration based on environment
- **Security First**: Private endpoints and zero-trust networking
- **Scalable Design**: Support for multiple spokes and environments

## Network Design

### IP Address Allocation
```
Hub VNet (10.0.0.0/16) - vnet-PRD-WEU-hub-001
├── AzureFirewallSubnet (10.0.1.0/26)
├── AzureBastionSubnet (10.0.2.0/27)
├── Shared Services (10.0.3.0/24) - snet-PRD-WEU-shared-001
├── Private Endpoints (10.0.4.0/24) - snet-PRD-WEU-pe-hub-001
└── Gateway Subnet (10.0.5.0/27)

Spoke Alpha VNet (10.1.0.0/16) - vnet-PRD-WEU-alpha-001
├── Workload Subnet (10.1.1.0/24) - snet-PRD-WEU-alpha-workload-001
├── Database Subnet (10.1.2.0/24) - snet-PRD-WEU-alpha-db-001
├── Private Endpoints (10.1.3.0/24) - snet-PRD-WEU-alpha-pe-001
└── VM Subnet (10.1.4.0/24) - snet-PRD-WEU-alpha-vm-001

Spoke Beta VNet (10.2.0.0/16) - vnet-PRD-WEU-beta-001
├── Workload Subnet (10.2.1.0/24) - snet-PRD-WEU-beta-workload-001
├── Database Subnet (10.2.2.0/24) - snet-PRD-WEU-beta-db-001
├── Private Endpoints (10.2.3.0/24) - snet-PRD-WEU-beta-pe-001
└── VM Subnet (10.2.4.0/24) - snet-PRD-WEU-beta-vm-001
```

### Connectivity Model
- **Hub-to-Spoke Peering**: Centralized connectivity
- **Spoke-to-Hub Routing**: All traffic via Azure Firewall
- **Private Endpoints**: Secure PaaS service access
- **Azure Bastion**: Secure VM management access

## Security Architecture

### Defense in Depth
1. **Network Level**: Azure Firewall with comprehensive rules
2. **Subnet Level**: Network Security Groups (NSGs)
3. **Application Level**: Private endpoints and secure protocols
4. **Identity Level**: Key Vault and managed identities
5. **Management Level**: Azure Bastion and just-in-time access

### Key Security Features
- **Zero Trust Networking**: No implicit trust, verify everything
- **Private Connectivity**: No public IPs on workload VMs
- **Centralized Logging**: All network traffic logged and monitored
- **Credential Management**: Automated password rotation via Key Vault
- **Encrypted Storage**: All data encrypted at rest and in transit

## Deployment Patterns

### Single Deployment (Hub Workspace)
- Deploys complete hub infrastructure
- Includes Spoke Alpha and Beta
- Suitable for development and testing

### Multi-Workspace Deployment
- Hub deployed separately
- Spokes deployed per environment
- Suitable for production with strict separation

### Environment Progression
1. **Development**: Single workspace deployment
2. **Staging**: Multi-workspace with production-like setup
3. **Production**: Full multi-workspace with governance

## Monitoring and Observability

### Built-in Monitoring
- **Azure Monitor**: Centralized logging and metrics
- **Network Watcher**: Network topology and diagnostics
- **Azure Security Center**: Security posture monitoring
- **Cost Management**: Spend tracking and optimization

### Custom Monitoring
- **Health Check Scripts**: Automated infrastructure validation
- **Cost Analysis**: Regular cost optimization reports
- **Backup Validation**: Automated backup testing
- **Performance Monitoring**: Application and infrastructure metrics

## Best Practices Implementation

### Terraform Best Practices
- **State Management**: Remote state with locking
- **Module Design**: Reusable, configurable modules
- **Variable Validation**: Input validation and type checking
- **Output Organization**: Structured, meaningful outputs

### Azure Best Practices
- **Resource Organization**: Logical resource grouping
- **Naming Conventions**: Consistent, descriptive naming
- **Security Configuration**: Least privilege access
- **Cost Optimization**: Right-sizing and automation

### DevOps Best Practices
- **Infrastructure as Code**: Version-controlled infrastructure
- **Automated Testing**: Pipeline validation and testing
- **Approval Gates**: Manual approvals for production
- **Rollback Capability**: Safe deployment with rollback options

## Maintenance and Operations

### Regular Tasks
- **Password Rotation**: Automated via Key Vault and pipelines
- **Cost Review**: Monthly cost analysis and optimization
- **Security Updates**: Automated VM patching and updates
- **Backup Validation**: Regular restore testing
- **Performance Monitoring**: Capacity planning and optimization

### Emergency Procedures
- **Incident Response**: Documented response procedures
- **Disaster Recovery**: Backup and restore procedures
- **Security Incidents**: Isolation and investigation procedures
- **Performance Issues**: Troubleshooting and resolution guides

This structure provides a comprehensive, scalable, and maintainable foundation for enterprise Azure infrastructure deployment using Terraform and Azure DevOps.
