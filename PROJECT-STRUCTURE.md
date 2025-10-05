# TRL Hub and Spoke Infrastructure - Project Structure

This document explains the restructured project organization using Option 2: Multiple Files, Single Module approach with comprehensive management capabilities.

## Project Structure (Updated)

```
Azure DevOps/
├── modules/                    # Core Terraform module (single module approach)
│   ├── main.tf                # Resource groups and core configuration
│   ├── network.tf             # All networking resources (hub, spokes, routing)
│   ├── security.tf            # Firewall, Bastion, Key Vault
│   ├── compute.tf             # Virtual machines and compute resources
│   ├── storage.tf             # Storage accounts and containers
│   ├── database.tf            # SQL and Cosmos DB resources
│   ├── variables.tf           # All input variables
│   ├── outputs.tf             # All output values
│   ├── locals.tf              # Local values and computed data
│   └── versions.tf            # Provider requirements
├── pipelines/                 # Azure DevOps pipeline configurations
│   ├── azure-pipelines.yml    # Main deployment pipeline
│   ├── destroy-pipeline.yml   # Infrastructure destruction pipeline
│   ├── init-pipeline.yml      # Terraform initialization pipeline
│   ├── plan-pipeline.yml      # Terraform planning pipeline
│   ├── apply-pipeline.yml     # Terraform apply pipeline
│   ├── password-rotation.yml  # VM password rotation pipeline
│   └── templates/             # Reusable pipeline templates (CLEANED UP)
│       ├── terraform-init.yml      # Terraform initialization template
│       ├── terraform-plan.yml      # Terraform planning template
│       ├── terraform-apply.yml     # Terraform apply template
│       ├── terraform-destroy.yml   # Terraform destroy template
│       ├── security-scan.yml       # Security scanning template
│       └── infrastructure-validation.yml # Infrastructure validation template
├── workspaces/                # Terraform workspaces for different deployments
│   ├── hub/                   # Hub infrastructure workspace
│   │   ├── main.tf            # Hub-specific configuration
│   │   ├── variables.tf       # Hub variables
│   │   └── outputs.tf         # Hub outputs
│   ├── management/            # Management infrastructure workspace
│   │   └── main.tf            # Management configuration
│   └── spokes/                # Spoke workspaces by environment
│       ├── dev/               # Development environment
│       │   └── main.tf        # Dev spoke configuration
│       ├── staging/           # Staging environment
│       │   └── main.tf        # Staging spoke configuration
│       └── prod/              # Production environment
│           └── main.tf        # Production spoke configuration
├── scripts/                   # Infrastructure management scripts (ENHANCED)
│   ├── vm-password-rotation.sh    # Automated VM password rotation
│   ├── cost-analysis.sh           # Cost analysis and optimization
│   ├── health-check.sh            # Infrastructure health monitoring
│   ├── backup-management.sh       # Backup operations and validation
│   ├── environment-cleanup.sh     # Environment cleanup and optimization
│   ├── init.sh                    # Terraform initialization
│   ├── plan.sh                    # Terraform planning
│   ├── apply.sh                   # Terraform apply
│   └── destroy.sh                 # Terraform destroy
├── README.md                  # Main project documentation (UPDATED)
├── CONTRIBUTING.md            # Contribution guidelines
├── PIPELINE-SETUP-GUIDE.md    # Complete pipeline implementation guide (UPDATED)
└── PROJECT-STRUCTURE.md       # This file - project structure documentation
```

## Multi-Subscription Architecture

### Subscription Layout
This project implements infrastructure across three dedicated Azure subscriptions:

| Environment     | Subscription       | Purpose               | Configuration                           |
|-----------------|--------------------|-----------------------|-----------------------------------------|
| **Development** | `Sub-TRL-dev-weu`  | Development workloads | B1s VMs, LRS storage, auto-shutdown     |
| **Staging**     | `Sub-TRL-int-weu`  | Integration testing   | B1s VMs, LRS storage, extended testing  |
| **Production**  | `Sub-TRL-prod-weu` | Production workloads  | B2s VMs, GRS storage, high availability |

### Subscription Security Model
- **Isolated service principals** per subscription
- **Environment-specific Key Vaults** for secret management
- **Subscription-level RBAC** with the least privilege access
- **Cross-subscription pipeline orchestration** via Azure DevOps

## Template Architecture (Cleaned Up)

### Removed Duplicates
- **plan-pipeline.yml**: Removed from templates (kept in pipelines root)
- **azure-pipelines.yml**: Removed from templates (kept in pipelines root)
- **destroy-pipeline.yml**: Removed from templates (kept in pipelines root)
- **password-rotation.yml**: Removed from templates (kept in pipelines root)

### Reusable Templates (pipelines/templates/)

#### **1. terraform-init.yml**
**Purpose**: Standardized Terraform initialization across workspaces
**Parameters**:
- `workspacePath`: Path to Terraform workspace
- `environmentName`: Environment identifier (dev/staging/prod)
- `serviceConnection`: Azure service connection name
- `terraformVersion`: Terraform version to use

**Usage Example**:
```yaml
- template: templates/terraform-init.yml
  parameters:
    workspacePath: 'workspaces/hub'
    environmentName: 'hub'
    serviceConnection: 'trl-hubspoke-prod-connection'
```

#### **2. terraform-plan.yml**
**Purpose**: Infrastructure planning with detailed analysis
**Features**:
- Plan file generation with timestamps
- Resource change counting and analysis
- Human-readable and JSON output formats
- Artifact publishing for later use

#### **3. terraform-apply.yml**
**Purpose**: Safe infrastructure deployment with validation
**Features**:
- Plan validation before apply
- Output generation and artifact publishing
- Cleanup and summary reporting
- Error handling and rollback support

#### **4. terraform-destroy.yml** (NEW)
**Purpose**: Controlled infrastructure destruction
**Features**:
- Multi-confirmation safety checks
- Destroy plan generation and review
- Resource cleanup verification
- Post-destruction validation

#### **5. security-scan.yml**
**Purpose**: Comprehensive security scanning
**Tools Integrated**:
- **tfsec**: Terraform security scanner
- **checkov**: Infrastructure compliance scanner
- **terrascan**: Policy compliance scanner
**Output**: JUnit test results and detailed security reports

#### **6. infrastructure-validation.yml** (NEW)
**Purpose**: Post-deployment infrastructure validation
**Validation Areas**:
- Network infrastructure (VNets, peering, routing)
- Security infrastructure (Firewall, Bastion, Key Vault)
- Compute infrastructure (VMs, extensions, health)
- Storage and database infrastructure

## Management Scripts Enhancement

### Security Scripts

#### **VM Password Rotation** (`scripts/vm-password-rotation.sh`)
**Multi-Subscription Support**: Works across Sub-TRL-dev-weu, Sub-TRL-int-weu, Sub-TRL-prod-weu
**Key Features**:
- Automatic VM discovery across subscriptions
- Secure password generation (16-character OpenSSL)
- Key Vault integration with timestamped secrets
- Backup password storage for rollback capability
- Comprehensive error handling and reporting

### Operations Scripts

#### **Health Check** (`scripts/health-check.sh`)
**Comprehensive Monitoring**:
- **VM Health**: Power state, agent status, boot diagnostics
- **Network Health**: VNet peering, routing tables, connectivity
- **Security Health**: Key Vault access, private endpoints, policies
- **Performance Metrics**: Resource utilization and availability

#### **Cost Analysis** (`scripts/cost-analysis.sh`)
**Cost Optimization Features**:
- **Multi-subscription analysis**: Aggregated cost reporting
- **Free tier monitoring**: Usage against Azure free limits
- **Optimization recommendations**: Right-sizing, reserved instances
- **Budget setup guidance**: Automated alert configuration

#### **Backup Management** (`scripts/backup-management.sh`)
**Backup Operations**:
- **VM Backups**: Recovery Services Vault automation
- **Database Backups**: Azure SQL automatic backup validation
- **Compliance Reporting**: Backup status across environments
- **Restore Testing**: Backup integrity verification

#### **Environment Cleanup** (`scripts/environment-cleanup.sh`)
**Resource Optimization**:
- **Storage Cleanup**: Old blob removal, container optimization
- **Snapshot Management**: Retention policy enforcement
- **Unused Resources**: Orphaned NIC and disk detection
- **Log Optimization**: Log Analytics retention tuning

## Deployment Architecture

### Workspace Isolation Strategy

#### **1. Hub Workspace** (`workspaces/hub/`)
**Purpose**: Shared infrastructure components
**Components**:
- Azure Firewall for centralized security
- Azure Bastion for secure access
- Key Vault for secret management
- Private DNS zones for name resolution

**State File**: `hub.terraform.tfstate`
**Service Connection**: Environment-specific (dev/staging/prod)

#### **2. Management Workspace** (`workspaces/management/`)
**Purpose**: Monitoring and governance infrastructure
**Components**:
- Log Analytics workspace
- Application Insights
- Azure Monitor dashboards
- Policy definitions and assignments

**State File**: `management.terraform.tfstate`
**Dependencies**: Independent of hub and spoke deployments

#### **3. Spoke Workspaces** (`workspaces/spokes/{env}/`)
**Purpose**: Environment-specific workload infrastructure
**Components**:
- Spoke virtual networks with workload subnets
- Virtual machines with Key Vault integration
- Storage accounts with private connectivity
- SQL databases with private endpoints

**State Files**: 
- `dev.terraform.tfstate`
- `staging.terraform.tfstate`
- `prod.terraform.tfstate`

**Dependencies**: Requires hub infrastructure for routing and DNS

### Pipeline Orchestration

#### **Sequential Deployment Flow**:
```
1. Hub Infrastructure (shared services)
   ↓
2. Management Infrastructure (monitoring)
   ↓
3. Development Spokes (parallel with management)
   ↓
4. Staging Spokes (after dev validation)
   ↓
5. Production Spokes (manual approval required)
```

#### **Template Usage in Pipelines**:
```yaml
# Example pipeline using templates
stages:
- stage: Initialize
  jobs:
  - job: InitHub
    steps:
    - template: templates/terraform-init.yml
      parameters:
        workspacePath: 'workspaces/hub'
        environmentName: 'hub'
        serviceConnection: 'trl-hubspoke-prod-connection'

- stage: Plan
  jobs:
  - job: PlanHub
    steps:
    - template: templates/terraform-plan.yml
      parameters:
        workspacePath: 'workspaces/hub'
        environmentName: 'hub'
        serviceConnection: 'trl-hubspoke-prod-connection'

- stage: SecurityScan
  jobs:
  - job: ScanInfrastructure
    steps:
    - template: templates/security-scan.yml
      parameters:
        scanPath: 'modules/'
        environmentName: 'hub'
```

## Benefits of Updated Structure

### **1. Template Standardization**
- **Consistency**: All environments use identical deployment patterns
- **Maintainability**: Update templates once, applies everywhere
- **Testing**: Templates can be tested independently
- **Documentation**: Clear parameter definitions and usage examples

### **2. Enhanced Management Scripts**
- **Automation**: Comprehensive automation for routine operations
- **Multi-Environment**: Single scripts work across all subscriptions
- **Security**: No hardcoded credentials, all secrets managed via Key Vault
- **Reporting**: Detailed reports for compliance and optimization

### **3. Pipeline Efficiency**
- **Reusable Components**: Templates reduce code duplication
- **Parallel Execution**: Multiple jobs and environments in parallel
- **Artifact Management**: Proper artifact flow between pipeline stages
- **Error Handling**: Comprehensive error handling and rollback capabilities

### **4. Security Enhancement**
- **No Secrets in Code**: All authentication via service connections
- **Environment Isolation**: Subscription-level security boundaries
- **Approval Workflows**: Manual gates for production changes
- **Audit Trail**: Complete deployment history and change tracking

This structure provides enterprise-grade infrastructure management with proper separation of concerns, security, and operational efficiency while maintaining the simplicity of a single Terraform module approach.
