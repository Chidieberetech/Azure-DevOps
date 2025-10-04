# Azure-DevOps
Azure DevOps is a cloud-based platform that provides integrated tools for software development teams. It includes everything you need to plan work, collaborate on code, build applications, test functionality, and deploy to production.

# Azure DevOps Hub and Spoke Infrastructure with Terraform

This project implements a secure Hub and Spoke network topology in Azure using Terraform, with all traffic routing through Azure Firewall and utilizing Azure free tier services.

## TRL Naming Convention

This project follows the standardized TRL naming convention: `<org>-<project>-<env>-<resourceType>[-<suffix>]`

- **Organization**: `trl`
- **Project**: `Azure.IAC.hubspoke` 
- **Environment**: `dev`, `staging`, `prod`
- **Resource Type**: See abbreviations table below
- **Suffix**: Optional descriptive suffix (e.g., `main`, `01`, `web`)

## Azure Resources and Naming Conventions

### Core Infrastructure

| Resource Type | Abbreviation | Max Length | Allowed Characters | Example |
|---------------|--------------|------------|-------------------|---------|
| Resource Group | `rg` | 90 | Alphanumeric, underscore, parentheses, hyphen, period | `trl-hubspoke-prod-rg-hub` |
| Virtual Network | `vnet` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-vnet-hub` |
| Subnet | `snet` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-snet-workload` |
| Network Interface | `nic` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-nic-vm01` |
| Public IP | `pip` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-pip-afw` |
| Load Balancer | `lb` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-lb-web` |
| Application Gateway | `agw` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-agw-web` |
| Traffic Manager | `tm` | 63 | Alphanumeric, hyphen | `trl-hubspoke-prod-tm` |
| Front Door | `fd` | 64 | Alphanumeric, hyphen | `trl-hubspoke-prod-fd` |
| CDN Profile | `cdnp` | 260 | Alphanumeric, hyphen | `trl-hubspoke-prod-cdnp` |
| CDN Endpoint | `cdne` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-cdne` |
| Express Route | `er` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-er` |
| VPN Gateway | `vpng` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-vpng` |
| Local Network Gateway | `lgw` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-lgw` |
| Virtual Network Gateway | `vgw` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-vgw` |

### Security & Identity

| Resource Type | Abbreviation | Max Length | Allowed Characters | Example |
|---------------|--------------|------------|-------------------|---------|
| Network Security Group | `nsg` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-nsg-web` |
| Route Table | `rt` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-rt-spoke1` |
| Azure Firewall | `afw` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-afw` |
| Firewall Policy | `afwp` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-afwp` |
| Bastion | `bas` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-bas` |
| Key Vault | `kv` | 24 | Alphanumeric, hyphen | `trl-hubspoke-prod-kv` |
| Private Endpoint | `pep` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-pep-sql` |
| Private DNS Zone | `pdns` | 63 | Alphanumeric, hyphen, period | `privatelink.database.windows.net` |
| User Assigned Identity | `id` | 128 | Alphanumeric, underscore, hyphen | `trl-hubspoke-prod-id-vm` |
| Network Watcher | `nw` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-nw` |
| DDoS Protection Plan | `ddos` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-ddos` |
| Web Application Firewall | `waf` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-waf` |

### Compute & Web

| Resource Type | Abbreviation | Max Length | Allowed Characters | Example |
|---------------|--------------|------------|-------------------|---------|
| Virtual Machine | `vm` | 64 (Win), 15 (Linux) | Alphanumeric, hyphen | `trl-hubspoke-prod-vm-web01` |
| VM Scale Set | `vmss` | 64 (Win), 15 (Linux) | Alphanumeric, hyphen | `trl-hubspoke-prod-vmss-web` |
| Availability Set | `avail` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-avail-web` |
| Managed Disk | `disk` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-disk-vm01-os` |
| Snapshot | `snap` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-snap-vm01` |
| Image | `img` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-img-web` |
| App Service Plan | `plan` | 40 | Alphanumeric, hyphen | `trl-hubspoke-prod-plan-web` |
| App Service | `app` | 60 | Alphanumeric, hyphen | `trl-hubspoke-prod-app-web` |
| Function App | `func` | 60 | Alphanumeric, hyphen | `trl-hubspoke-prod-func-api` |
| Static Web App | `stapp` | 40 | Alphanumeric, hyphen | `trl-hubspoke-prod-stapp` |
| Logic App | `logic` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-logic` |
| Batch Account | `ba` | 24 | Lowercase alphanumeric | `trlhubspokeprodba` |

### Data & Storage

| Resource Type | Abbreviation | Max Length | Allowed Characters | Example |
|---------------|--------------|------------|-------------------|---------|
| Storage Account | `st` | 24 | Lowercase alphanumeric | `trlhubspokeprodst` |
| Storage Container | `stct` | 63 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-stct` |
| File Share | `fs` | 63 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-fs` |
| Queue | `stq` | 63 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-stq` |
| Table | `stt` | 63 | Alphanumeric | `trlhubspokeprodtable` |
| SQL Server | `sql` | 63 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-sql` |
| SQL Database | `sqldb` | 128 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-sqldb-main` |
| SQL Elastic Pool | `sqlep` | 128 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-sqlep` |
| SQL Managed Instance | `sqlmi` | 63 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-sqlmi` |
| Cosmos DB | `cosmos` | 44 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-cosmos` |
| Redis Cache | `redis` | 63 | Alphanumeric, hyphen | `trl-hubspoke-prod-redis` |
| MySQL Database | `mysql` | 63 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-mysql` |
| PostgreSQL Database | `psql` | 63 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-psql` |
| MariaDB Database | `mariadb` | 63 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-mariadb` |
| Data Factory | `adf` | 63 | Alphanumeric, hyphen | `trl-hubspoke-prod-adf` |
| Synapse Workspace | `syn` | 45 | Alphanumeric, hyphen | `trl-hubspoke-prod-syn` |
| Analysis Services | `as` | 63 | Lowercase alphanumeric | `trlhubspokeprods` |
| Data Lake Store | `dls` | 24 | Lowercase alphanumeric | `trlhubspokeprodls` |
| Data Lake Analytics | `dla` | 24 | Lowercase alphanumeric | `trlhubspokeprodla` |
| HDInsight Cluster | `hdi` | 59 | Alphanumeric, hyphen | `trl-hubspoke-prod-hdi` |
| Power BI Embedded | `pbi` | 63 | Alphanumeric, hyphen | `trl-hubspoke-prod-pbi` |

### Containers & DevOps

| Resource Type | Abbreviation | Max Length | Allowed Characters | Example |
|---------------|--------------|------------|-------------------|---------|
| Container Registry | `cr` | 50 | Alphanumeric | `trlhubspokeprodcr` |
| Kubernetes Service | `aks` | 63 | Alphanumeric, hyphen | `trl-hubspoke-prod-aks` |
| Container Instance | `ci` | 63 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-ci-web` |
| Container App | `ca` | 32 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-ca` |
| Service Fabric Cluster | `sf` | 23 | Lowercase alphanumeric | `trlhubspokeprodcluster` |
| Service Bus Namespace | `sb` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-sb` |
| Service Bus Queue | `sbq` | 50 | Alphanumeric, hyphen, underscore, period | `trl-hubspoke-prod-sbq-orders` |
| Service Bus Topic | `sbt` | 50 | Alphanumeric, hyphen, underscore, period | `trl-hubspoke-prod-sbt-events` |
| Event Hub Namespace | `evhns` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-evhns` |
| Event Hub | `evh` | 50 | Alphanumeric, hyphen, underscore, period | `trl-hubspoke-prod-evh-logs` |
| Event Grid Domain | `egd` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-egd` |
| Event Grid Topic | `egt` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-egt` |
| IoT Hub | `iot` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-iot` |
| Notification Hub | `ntf` | 260 | Alphanumeric, hyphen | `trl-hubspoke-prod-ntf` |
| DevTest Lab | `dtl` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-dtl` |

### Monitoring & Management

| Resource Type | Abbreviation | Max Length | Allowed Characters | Example |
|---------------|--------------|------------|-------------------|---------|
| Log Analytics Workspace | `log` | 63 | Alphanumeric, hyphen | `trl-hubspoke-prod-log` |
| Application Insights | `appi` | 260 | Unicode characters | `trl-hubspoke-prod-appi-web` |
| Action Group | `ag` | 260 | Unicode characters | `trl-hubspoke-prod-ag` |
| Alert Rule | `ar` | 260 | Unicode characters | `trl-hubspoke-prod-ar` |
| Recovery Services Vault | `rsv` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-rsv` |
| Backup Vault | `bv` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-bv` |
| Site Recovery Vault | `srv` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-srv` |
| Automation Account | `aa` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-aa` |
| Managed Grafana | `amg` | 23 | Alphanumeric, hyphen | `trl-hubspoke-prod-amg` |
| Dashboard | `dash` | 160 | Unicode characters | `trl-hubspoke-prod-dash` |
| Workbook | `wb` | 260 | Unicode characters | `trl-hubspoke-prod-wb` |
| Policy Definition | `policy` | 128 | Unicode characters | `trl-hubspoke-prod-policy-deny-pip` |
| Policy Assignment | `assign` | 128 | Unicode characters | `trl-hubspoke-prod-assign-deny-pip` |
| Blueprint | `bp` | 48 | Alphanumeric, hyphen, underscore, period | `trl-hubspoke-prod-bp` |
| Management Group | `mg` | 90 | Alphanumeric, underscore, parentheses, hyphen, period | `trl-hubspoke-prod-mg` |

### AI & Cognitive Services

| Resource Type | Abbreviation | Max Length | Allowed Characters | Example |
|---------------|--------------|------------|-------------------|---------|
| Cognitive Services | `cog` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-cog-vision` |
| Computer Vision | `cv` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-cv` |
| Custom Vision | `cusv` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-cusv` |
| Face API | `face` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-face` |
| Form Recognizer | `fr` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-fr` |
| Language Understanding | `luis` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-luis` |
| QnA Maker | `qna` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-qna` |
| Speech Service | `speech` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-speech` |
| Text Analytics | `ta` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-ta` |
| Translator | `trans` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-trans` |
| Bot Service | `bot` | 64 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-bot` |
| Machine Learning Workspace | `mlw` | 260 | Unicode characters | `trl-hubspoke-prod-mlw` |
| Machine Learning Compute | `mlc` | 24 | Alphanumeric, hyphen | `trl-hubspoke-prod-mlc` |
| Search Service | `srch` | 60 | Lowercase alphanumeric, hyphen | `trl-hubspoke-prod-srch` |
| Maps Account | `map` | 98 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-map` |

### Integration & API

| Resource Type | Abbreviation | Max Length | Allowed Characters | Example |
|---------------|--------------|------------|-------------------|---------|
| API Management | `apim` | 50 | Alphanumeric, hyphen | `trl-hubspoke-prod-apim` |
| Logic App | `logic` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-logic` |
| Integration Account | `ia` | 80 | Alphanumeric, underscore, hyphen, period | `trl-hubspoke-prod-ia` |
| Data Factory | `df` | 63 | Alphanumeric, hyphen | `trl-hubspoke-prod-df` |
| Data Factory Pipeline | `dfp` | 260 | Alphanumeric, hyphen, underscore, period | `trl-hubspoke-prod-dfp` |
| Stream Analytics | `asa` | 63 | Alphanumeric, hyphen, underscore | `trl-hubspoke-prod-asa` |
| Power Automate | `flow` | 260 | Unicode characters | `trl-hubspoke-prod-flow` |

### Media & Communication

| Resource Type | Abbreviation | Max Length | Allowed Characters | Example |
|---------------|--------------|------------|-------------------|---------|
| Media Services | `ams` | 24 | Lowercase alphanumeric | `trlhubspokeprodams` |
| Communication Services | `acs` | 63 | Alphanumeric, hyphen | `trl-hubspoke-prod-acs` |
| SignalR Service | `sigr` | 63 | Alphanumeric, hyphen | `trl-hubspoke-prod-sigr` |
| Web PubSub | `wps` | 63 | Alphanumeric, hyphen | `trl-hubspoke-prod-wps` |

## Character Restrictions Summary

### Common Rules:
- **No spaces allowed** in any resource names
- **Case sensitivity varies** by resource type
- **Special characters** are limited and resource-specific
- **Global uniqueness required** for some resources (Storage Accounts, Key Vaults, etc.)

### Character Categories:
- **Alphanumeric**: `a-z`, `A-Z`, `0-9`
- **Hyphen**: `-` (not at start/end for most resources)
- **Underscore**: `_`
- **Period**: `.`
- **Parentheses**: `()`

### Length Considerations:
- Consider the **full naming convention length** when planning
- Leave room for **environment suffixes** and **incremental numbers**
- Some resources have **very short limits** (Storage Accounts: 24 chars)
- Plan for **automated deployments** that might add suffixes

## Architecture Overview

### Hub and Spoke Topology
- **Hub VNet**: Contains shared services (Azure Firewall, Bastion, Key Vault)
- **Spoke VNets**: Contains workload resources (VMs, databases, storage)
- **Azure Firewall**: Centralized security enforcement in West Europe
- **Azure Bastion**: Secure RDP/SSH access without public IPs
- **Key Vault**: Centralized secrets and credential management
- **Private Endpoints**: All Azure PaaS services accessed privately

### Security Features
- No public IPs on VMs
- All traffic routed through Azure Firewall
- Private endpoints for all Azure services
- Azure Bastion for secure remote access
- Key Vault integration for all credentials
- **NO Network Security Groups (NSGs)** - All traffic managed by Azure Firewall

## Step-by-Step Solution Architecture

### Phase 1: Foundation Setup

#### Step 1: Azure Subscription and Resource Groups
```
1. Create Azure subscription (free tier)
2. Set up service principal for Terraform
3. Create resource groups:
   - rg-hub-prod-we (Hub resources)
   - rg-spoke-prod-we (Spoke resources)
   - rg-shared-prod-we (Shared services)
```

#### Step 2: Terraform State Management
```
1. Create storage account for Terraform state
2. Configure backend configuration
3. Set up state locking with blob lease
```

### Phase 2: Network Infrastructure

#### Step 3: Hub Virtual Network
```
1. Create Hub VNet (10.0.0.0/16)
   - AzureFirewallSubnet (10.0.1.0/26)
   - AzureBastionSubnet (10.0.2.0/27)
   - SharedServicesSubnet (10.0.3.0/24)
   - PrivateEndpointSubnet (10.0.4.0/24)
```

#### Step 4: Spoke Virtual Networks
```
1. Create Spoke VNet 1 (10.1.0.0/16)
   - WorkloadSubnet (10.1.1.0/24)
   - DatabaseSubnet (10.1.2.0/24)
   - PrivateEndpointSubnet (10.1.3.0/24)

2. Create Spoke VNet 2 (10.2.0.0/16)
   - WorkloadSubnet (10.2.1.0/24)
   - AppServiceSubnet (10.2.2.0/24)
   - PrivateEndpointSubnet (10.2.3.0/24)
```

#### Step 5: VNet Peering
```
1. Hub to Spoke 1 peering
2. Hub to Spoke 2 peering
3. Configure gateway transit
4. Allow forwarded traffic
```

### Phase 3: Security Infrastructure

#### Step 6: Azure Firewall Deployment
```
1. Create Azure Firewall in Hub VNet
2. Create public IP for Azure Firewall
3. Configure firewall policy
4. Set up application rules
5. Set up network rules
6. Configure NAT rules for management
```

#### Step 7: Route Tables Configuration
```
1. Create route table for spoke subnets
2. Add default route (0.0.0.0/0) to Azure Firewall
3. Associate route tables with spoke subnets
4. Configure hub subnet routing
```

#### Step 8: Network Security Groups
```
1. Create NSGs for each subnet type
2. Configure inbound/outbound rules
3. Associate NSGs with subnets
4. Implement least privilege access
```

### Phase 4: Key Management

#### Step 9: Azure Key Vault Setup
```
1. Create Key Vault in hub network
2. Configure private endpoint
3. Set up access policies
4. Generate VM login credentials
5. Store SSL certificates
6. Configure network access restrictions
```

#### Step 10: Managed Identity Configuration
```
1. Create system-assigned managed identities
2. Configure Key Vault access policies
3. Set up role assignments
4. Test secret retrieval
```

### Phase 5: Compute Resources

#### Step 11: Azure Bastion Deployment
```
1. Create Azure Bastion in hub network
2. Configure Standard SKU for enhanced features
3. Set up IP configurations
4. Test connectivity to spoke VMs
```

#### Step 12: Virtual Machines (Free Tier)
```
1. Deploy B1s VMs in spoke networks (750 hours free)
2. Configure VM extensions for Key Vault
3. Set up automatic credential rotation
4. Install required monitoring agents
```

### Phase 6: Storage and Data Services

#### Step 13: Storage Accounts (Free Tier)
```
1. Create storage accounts with private endpoints
2. Configure LRS replication (5GB free)
3. Set up file shares (1GB free)
4. Implement backup retention policies
```

#### Step 14: Azure SQL Database (Free Tier)
```
1. Deploy SQL Database S0 tier (31 DTU days free)
2. Configure private endpoint
3. Set up database firewall rules
4. Implement backup and recovery
```

#### Step 15: Azure Cosmos DB (Free Tier)
```
1. Create Cosmos DB account (25GB + 1000 RU/s free)
2. Configure private endpoint
3. Set up database and containers
4. Implement backup policies
```

### Phase 7: Application Services

#### Step 16: Container Registry (Free Tier)
```
1. Create Azure Container Registry (31 days free)
2. Configure private endpoint
3. Set up service connection
4. Implement image security scanning
```

#### Step 17: Load Balancer (Free Tier)
```
1. Deploy Standard Load Balancer (5 rules free)
2. Configure backend pools
3. Set up health probes
4. Implement traffic distribution
```

### Phase 8: Monitoring and Governance

#### Step 18: Azure Monitor Setup
```
1. Configure Log Analytics workspace
2. Set up diagnostic settings
3. Create custom dashboards
4. Implement alerting rules
```

#### Step 19: Backup and Recovery
```
1. Create Recovery Services Vault
2. Configure VM backup policies
3. Set up database backup
4. Test restore procedures
```

### Phase 9: DevOps Integration

#### Step 20: Azure DevOps Setup
```
1. Create Azure DevOps organization
2. Set up project and repositories
3. Configure service connections
4. Create build and release pipelines
```

#### Step 21: Terraform Pipeline
```
1. Create Terraform plan pipeline
2. Set up approval gates
3. Configure state file management
4. Implement infrastructure drift detection
```

## Free Tier Services Utilized

### Compute (750 hours/month each)
- Virtual Machines BS Series B1s
- Virtual Machines BS Series Windows B1s
- Virtual Machines Bpsv2 Series B2pts v2
- Virtual Machines Basv2 Series B2ats v2

### Storage (Monthly limits)
- 5GB Hot LRS Blob Storage
- 1GB File Storage LRS
- 32GB Database Storage
- 10GB Archive Storage

### Networking (Monthly limits)
- 15GB Data Transfer Out
- 1,500 Public IP Address Hours
- Standard Load Balancer (5 rules)
- VPN Gateway (750 hours)

### Databases
- SQL Database S0 (31 DTU days)
- Cosmos DB (25GB + 1000 RU/s)
- PostgreSQL/MySQL Flexible Server B1MS (750 hours)

### Security and Management
- Key Vault (10,000 Premium HSM operations)
- Service Bus Standard (750 hours)
- Container Registry Standard (31 days)

## Terraform Structure

```
terraform/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/
│   ├── network/
│   │   ├── hub/
│   │   └── spoke/
│   ├── security/
│   │   ├── firewall/
│   │   ├── bastion/
│   │   └── keyvault/
│   ├── compute/
│   │   └── vm/
│   ├── storage/
│   └── database/
├── scripts/
└── docs/
```

## Implementation Timeline

### Week 1: Foundation
- Azure setup and Terraform configuration
- Network infrastructure deployment
- Security baseline implementation

### Week 2: Core Services
- Virtual machines and storage
- Database services
- Application services

### Week 3: DevOps Integration
- Pipeline configuration
- Monitoring setup
- Testing and validation

### Week 4: Optimization
- Performance tuning
- Security hardening
- Documentation completion

## Security Considerations

### Network Security
- Zero trust network model
- Private endpoints for all PaaS services
- Centralized firewall filtering
- No direct internet access from VMs

### Identity and Access
- Managed identities where possible
- Key Vault for all secrets
- RBAC implementation
- Regular access reviews

### Data Protection
- Encryption at rest and in transit
- Private connectivity only
- Backup and disaster recovery
- Compliance monitoring

## Cost Optimization

### Free Tier Maximization
- Monitor usage against limits
- Implement auto-shutdown for VMs
- Use reserved instances for predictable workloads
- Regular cost analysis and optimization

### Resource Management
- Tagging strategy for cost allocation
- Automated resource cleanup
- Right-sizing recommendations
- Budget alerts and controls

## Next Steps

1. Clone this repository
2. Set up Azure subscription and service principal
3. Configure Terraform backend
4. Deploy hub network infrastructure
5. Add spoke networks incrementally
6. Implement monitoring and governance
7. Set up DevOps pipelines
8. Begin application deployment

## Support and Documentation

- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)
- [Azure Free Account Limits](https://azure.microsoft.com/en-us/free/free-account-faq/)

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## Terraform Module Architecture

This project uses a modular Terraform approach to ensure code reusability, maintainability, and separation of concerns. Each module represents a specific functional area of the Azure infrastructure.

### Module Structure Explained

Every Terraform module in this project follows a standardized structure:

```
module_name/
├── main.tf          # Primary resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider requirements
└── README.md        # Module documentation
```

#### File Purposes:

- **`main.tf`**: Contains the primary resource definitions and logic for the module
- **`variables.tf`**: Defines input parameters that make the module configurable and reusable
- **`outputs.tf`**: Exposes important resource attributes for use by other modules or root configurations
- **`versions.tf`**: Specifies Terraform and provider version requirements for compatibility
- **`README.md`**: Documents the module's purpose, usage, inputs, and outputs

### Hub and Spoke Modules Overview

#### Network Modules

##### 1. Hub Network Module (`terraform/modules/network/hub/`)

**Purpose**: Creates the central hub virtual network containing shared services

**Main Resources**:
- Hub Virtual Network (10.0.0.0/16)
- Azure Firewall Subnet (required for firewall deployment)
- Azure Bastion Subnet (required for bastion service)
- Shared Services Subnet (for Key Vault and other shared resources)
- Private Endpoint Subnet (for private connectivity to PaaS services)

**Key Variables**:
```hcl
variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

variable "hub_address_space" {
  description = "Address space for hub VNet"
  type        = list(string)
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}
```

**Main Outputs**:
```hcl
output "vnet_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "firewall_subnet_id" {
  description = "ID of the Azure Firewall subnet"
  value       = azurerm_subnet.firewall.id
}

output "bastion_subnet_id" {
  description = "ID of the Azure Bastion subnet" 
  value       = azurerm_subnet.bastion.id
}
```

##### 2. Spoke Network Module (`terraform/modules/network/spoke/`)

**Purpose**: Creates spoke virtual networks for workload isolation with routing through the hub

**Main Resources**:
- Spoke Virtual Network
- Workload Subnet (for VMs and applications)
- Database Subnet (for database resources)
- Private Endpoint Subnet (for service connectivity)
- Route Tables (directing traffic to Azure Firewall)
- VNet Peering (connecting to hub network)

**Key Variables**:
```hcl
variable "spoke_vnet_name" {
  description = "Name of the spoke virtual network"
  type        = string
}

variable "hub_vnet_id" {
  description = "ID of the hub virtual network for peering"
  type        = string
}

variable "firewall_private_ip" {
  description = "Private IP of Azure Firewall for routing"
  type        = string
}
```

**Main Outputs**:
```hcl
output "workload_subnet_id" {
  description = "ID of the workload subnet"
  value       = azurerm_subnet.workload.id
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.database.id
}
```

#### Security Modules

##### 3. Azure Firewall Module (`terraform/modules/security/firewall/`)

**Purpose**: Implements centralized network security and traffic filtering

**Main Resources**:
- Azure Firewall (Standard tier)
- Public IP for firewall
- Firewall Policy with rules
- Application rules (web traffic, updates)
- Network rules (DNS, NTP)
- NAT rules (management access)

**Key Variables**:
```hcl
variable "firewall_name" {
  description = "Name of the Azure Firewall"
  type        = string
}

variable "firewall_subnet_id" {
  description = "ID of the firewall subnet"
  type        = string
}
```

**Main Outputs**:
```hcl
output "private_ip_address" {
  description = "Private IP address of Azure Firewall"
  value       = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "public_ip_address" {
  description = "Public IP address of Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}
```

##### 4. Azure Bastion Module (`terraform/modules/security/bastion/`)

**Purpose**: Provides secure RDP/SSH access to VMs without public IPs

**Main Resources**:
- Azure Bastion Host (Standard SKU)
- Public IP for bastion service
- Enhanced features (file copy, tunneling)

**Key Variables**:
```hcl
variable "bastion_name" {
  description = "Name of the Azure Bastion"
  type        = string
}

variable "bastion_subnet_id" {
  description = "ID of the bastion subnet"
  type        = string
}
```

**Main Outputs**:
```hcl
output "fqdn" {
  description = "FQDN of the Azure Bastion"
  value       = azurerm_bastion_host.main.dns_name
}
```

##### 5. Key Vault Module (`terraform/modules/security/keyvault/`)

**Purpose**: Centralizes secrets, keys, and certificate management

**Main Resources**:
- Azure Key Vault with private access
- Private endpoint for secure connectivity
- Access policies for service principals
- Auto-generated secrets (VM passwords, SQL credentials)
- Private DNS zone for Key Vault resolution

**Key Variables**:
```hcl
variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
}
```

**Main Outputs**:
```hcl
output "key_vault_id" {
  description = "ID of the Azure Key Vault"
  value       = azurerm_key_vault.main.id
}

output "vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}
```

#### Compute Module

##### 6. Virtual Machine Module (`terraform/modules/compute/vm/`)

**Purpose**: Deploys secure virtual machines integrated with Key Vault

**Main Resources**:
- Windows Virtual Machine (Standard_B1s for free tier)
- Network Interface (no public IP)
- Key Vault integration for credentials
- VM extensions for Key Vault access
- Auto-shutdown schedule for cost optimization

**Key Variables**:
```hcl
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for VM deployment"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID for credential retrieval"
  type        = string
}
```

**Main Outputs**:
```hcl
output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.vm.id
}
```

#### Storage Module

##### 7. Storage Module (`terraform/modules/storage/`)

**Purpose**: Provides secure storage services with private connectivity

**Main Resources**:
- Storage Account (LRS replication for free tier)
- Private endpoints for blob and file storage
- Storage containers and file shares
- Private DNS zones for storage resolution
- Encryption and security configurations

**Key Variables**:
```hcl
variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet for private endpoints"
  type        = string
}
```

**Main Outputs**:
```hcl
output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}
```

#### Database Module

##### 8. Database Module (`terraform/modules/database/`)

**Purpose**: Deploys secure database services with private access

**Main Resources**:
- Azure SQL Server and Database (S0 tier for free tier)
- Private endpoint for database connectivity
- Key Vault integration for admin credentials
- Backup and security configurations
- Private DNS zone for SQL resolution

**Key Variables**:
```hcl
variable "sql_server_name" {
  description = "Name of the SQL Server"
  type        = string
}

variable "database_name" {
  description = "Name of the SQL Database"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID for credential storage"
  type        = string
}
```

**Main Outputs**:
```hcl
output "server_fqdn" {
  description = "Fully qualified domain name of SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "database_id" {
  description = "ID of the SQL Database"
  value       = azurerm_mssql_database.main.id
}
```

#### Private DNS Module

##### 9. Private DNS Module (`terraform/modules/private_dns/`)

**Purpose**: Ensures all Azure PaaS services resolve privately within the network

**Main Resources**:
- Private DNS zones for all Azure services
- VNet links for hub and spoke networks
- DNS zone configurations for:
  - Key Vault (`privatelink.vaultcore.azure.net`)
  - Storage (`privatelink.blob.core.windows.net`)
  - SQL Database (`privatelink.database.windows.net`)
  - Cosmos DB (`privatelink.documents.azure.com`)

**Key Variables**:
```hcl
variable "hub_vnet_id" {
  description = "Hub virtual network ID"
  type        = string
}

variable "spoke_vnet_ids" {
  description = "List of spoke VNet IDs"
  type        = list(string)
}
```

**Main Outputs**:
```hcl
output "keyvault_dns_zone_id" {
  description = "ID of Key Vault private DNS zone"
  value       = azurerm_private_dns_zone.keyvault.id
}
```

### Module Benefits

#### 1. **Reusability**
- Modules can be used across different environments (dev, staging, prod)
- Same module with different variable inputs creates consistent infrastructure

#### 2. **Maintainability** 
- Changes to a module automatically apply to all uses
- Easier to update and patch infrastructure components

#### 3. **Testing**
- Individual modules can be tested in isolation
- Reduces blast radius of changes

#### 4. **Security**
- Enforces consistent security patterns across deployments
- Centralized security configurations

#### 5. **Compliance**
- Ensures all deployments follow organizational standards
- Built-in governance and policy enforcement

### Variable Types and Usage

#### Input Variables
Variables make modules flexible and reusable:

```hcl
# String variables for names and configuration
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

# List variables for multiple values
variable "address_space" {
  description = "Address space for VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# Object variables for complex configurations
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Boolean variables for feature flags
variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = true
}
```

#### Output Values
Outputs share important resource information:

```hcl
# Resource IDs for cross-module references
output "subnet_id" {
  description = "ID of the created subnet"
  value       = azurerm_subnet.main.id
}

# Configuration values for dependent resources
output "private_ip_address" {
  description = "Private IP address"
  value       = azurerm_network_interface.main.private_ip_address
}

# Complex objects for multiple related values
output "network_config" {
  description = "Network configuration details"
  value = {
    vnet_id     = azurerm_virtual_network.main.id
    subnet_id   = azurerm_subnet.main.id
    address_space = azurerm_virtual_network.main.address_space
  }
}
```

### Module Dependencies

The modules have clear dependencies that ensure proper deployment order:

1. **Hub Network** → Foundation for all other resources
2. **Private DNS** → Requires hub network for DNS resolution
3. **Key Vault** → Depends on hub network and private DNS
4. **Firewall** → Requires hub network and firewall subnet
5. **Bastion** → Depends on hub network and bastion subnet
6. **Spoke Networks** → Requires hub network and firewall IP
7. **Virtual Machines** → Depends on spoke networks and Key Vault
8. **Storage/Database** → Requires spoke networks, private DNS, and Key Vault

This modular approach ensures that the infrastructure is deployed in the correct order while maintaining clean separation of concerns and enabling easy testing and maintenance.
