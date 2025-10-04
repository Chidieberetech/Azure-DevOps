# TRL Hub and Spoke Infrastructure - Project Structure

This document explains the restructured project organization using Option 2: Multiple Files, Single Module approach.

## Project Structure

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
│   └── destroy-pipeline.yml   # Infrastructure destruction pipeline
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
├── README.md                  # Main project documentation
└── CONTRIBUTING.md            # Contribution guidelines
```

## Workspace Architecture

### 1. Hub Workspace (`workspaces/hub/`)
**Purpose**: Deploys shared infrastructure components
- Azure Firewall for centralized security
- Azure Bastion for secure VM access
- Key Vault for secrets management
- Private DNS zones for internal resolution
- Hub virtual network with required subnets

### 2. Management Workspace (`workspaces/management/`)
**Purpose**: Deploys monitoring and governance infrastructure
- Log Analytics workspace
- Application Insights
- Monitoring dashboards
- Azure policies and governance

### 3. Spoke Workspaces (`workspaces/spokes/*/`)
**Purpose**: Deploys environment-specific workload infrastructure
- **Dev**: Development workloads with auto-shutdown
- **Staging**: Pre-production testing environment
- **Prod**: Production workloads with high availability

## Deployment Flow

### 1. Infrastructure Dependencies
```
Hub Infrastructure → Management Infrastructure
                  ↘ Dev Spokes
                  ↘ Staging Spokes → Production Spokes
```

### 2. Pipeline Workflow
1. **Validation**: Validate all Terraform configurations
2. **Hub Deployment**: Deploy shared hub infrastructure
3. **Management Deployment**: Deploy monitoring and governance
4. **Spoke Deployments**: Deploy environment-specific workloads
   - Dev (parallel with management)
   - Staging (after dev)
   - Production (manual approval required)
5. **Validation**: Post-deployment infrastructure verification

## Module Configuration

### Core Module (`modules/`)
The single module contains all resource definitions organized by function:

- **main.tf**: Resource groups and foundational resources
- **network.tf**: Hub/spoke networking, VNet peering, routing
- **security.tf**: Azure Firewall, Bastion, Key Vault, private endpoints
- **compute.tf**: Virtual machines with Key Vault integration
- **storage.tf**: Storage accounts with private connectivity
- **database.tf**: SQL Database and Cosmos DB with private endpoints

### Workspace Consumption
Each workspace imports the core module with specific configurations:

```hcl
module "infrastructure" {
  source = "../../modules"  # or "../../../modules" for spokes
  
  environment = "dev"       # Environment-specific
  spoke_count = 2          # Workspace-specific settings
  enable_firewall = false  # Hub manages firewall
  # ... other variables
}
```

## Benefits of This Structure

### 1. **Simplified Maintenance**
- Single module to maintain instead of multiple separate modules
- Changes apply consistently across all environments
- Easier to understand the full infrastructure picture

### 2. **Environment Isolation**
- Separate Terraform state files per workspace
- Independent deployment cycles
- Environment-specific configurations

### 3. **Deployment Flexibility**
- Can deploy hub without spokes
- Can deploy specific environments independently
- Easy to add new environments

### 4. **Pipeline Efficiency**
- Clear deployment dependencies
- Parallel deployment where possible
- Automated validation and approval gates

## Usage Instructions

### Local Development
```bash
# Initialize hub workspace
cd workspaces/hub
terraform init
terraform plan
terraform apply

# Initialize spoke workspace
cd ../spokes/dev
terraform init
terraform plan
terraform apply
```

### Pipeline Deployment
1. Push changes to trigger pipeline
2. Pipeline validates all configurations
3. Deploys hub infrastructure first
4. Deploys spokes based on branch (dev/staging auto, prod with approval)

### Environment Management
- **Add new environment**: Create new folder under `workspaces/spokes/`
- **Modify infrastructure**: Update the core module in `modules/`
- **Environment-specific changes**: Modify workspace configuration

This structure provides the simplicity of a single module while maintaining the flexibility and isolation needed for enterprise infrastructure management.
