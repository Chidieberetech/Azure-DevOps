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

| Resource Type           | Abbreviation | Max Length | Allowed Characters                                    | Example                           |
|-------------------------|--------------|------------|-------------------------------------------------------|-----------------------------------|
| Resource Group          | `rg`         | 90         | Alphanumeric, underscore, parentheses, hyphen, period | `rg-trl-PRD-alpha-001`            |
| Virtual Network         | `vnet`       | 64         | Alphanumeric, underscore, hyphen, period              | `vnet-PRD-WEU-hub-001`            |
| Subnet                  | `snet`       | 80         | Alphanumeric, underscore, hyphen, period              | `snet-PRD-WEU-alpha-vm-001`       |
| Network Interface       | `nic`        | 80         | Alphanumeric, underscore, hyphen, period              | `nic-PRD-WEU-alpha-vm-001`        |
| Public IP               | `pip`        | 80         | Alphanumeric, underscore, hyphen, period              | `pip-PRD-WEU-afw-001`             |
| Load Balancer           | `lb`         | 80         | Alphanumeric, underscore, hyphen, period              | `lb-PRD-WEU-web-001`              |
| Application Gateway     | `agw`        | 80         | Alphanumeric, underscore, hyphen, period              | `agw-PRD-WEU-web-001`             |
| Traffic Manager         | `tm`         | 63         | Alphanumeric, hyphen                                  | `tm-PRD-WEU-001`                  |
| Front Door              | `fd`         | 64         | Alphanumeric, hyphen                                  | `fd-PRD-WEU-001`                  |
| CDN Profile             | `cdnp`       | 260        | Alphanumeric, hyphen                                  | `cdnp-PRD-WEU-001`                |
| CDN Endpoint            | `cdne`       | 50         | Alphanumeric, hyphen                                  | `cdne-PRD-WEU-001`                |
| Express Route           | `er`         | 80         | Alphanumeric, underscore, hyphen, period              | `er-PRD-WEU-001`                  |
| VPN Gateway             | `vpng`       | 80         | Alphanumeric, underscore, hyphen, period              | `vpng-PRD-WEU-001`                |
| Local Network Gateway   | `lgw`        | 80         | Alphanumeric, underscore, hyphen, period              | `lgw-PRD-WEU-001`                 |
| Virtual Network Gateway | `vgw`        | 80         | Alphanumeric, underscore, hyphen, period              | `vgw-PRD-WEU-001`                 |

### Security & Identity

| Resource Type            | Abbreviation | Max Length | Allowed Characters                       | Example                            |
|--------------------------|--------------|------------|------------------------------------------|------------------------------------|
| Network Security Group   | `nsg`        | 80         | Alphanumeric, underscore, hyphen, period | `nsg-PRD-WEU-hub-001`              |
| Route Table              | `rt`         | 80         | Alphanumeric, underscore, hyphen, period | `rt-PRD-WEU-alpha-001`             |
| Azure Firewall           | `afw`        | 80         | Alphanumeric, underscore, hyphen, period | `afw-PRD-WEU-001`                  |
| Firewall Policy          | `afwp`       | 80         | Alphanumeric, underscore, hyphen, period | `afwp-PRD-WEU-001`                 |
| Bastion                  | `bas`        | 80         | Alphanumeric, underscore, hyphen, period | `bastion-PRD-WEU-001`              |
| Key Vault                | `kv`         | 24         | Alphanumeric, hyphen                     | `kv-PRD-WEU-001`                   |
| Private Endpoint         | `pep`        | 80         | Alphanumeric, underscore, hyphen, period | `pep-PRD-WEU-sql-001`              |
| Private DNS Zone         | `pdns`       | 63         | Alphanumeric, hyphen, period             | `privatelink.database.windows.net` |
| User Assigned Identity   | `id`         | 128        | Alphanumeric, underscore, hyphen         | `id-PRD-WEU-vm-001`                |
| Network Watcher          | `nw`         | 80         | Alphanumeric, underscore, hyphen, period | `nw-PRD-WEU-001`                   |
| DDoS Protection Plan     | `ddos`       | 80         | Alphanumeric, underscore, hyphen, period | `ddos-PRD-WEU-001`                 |
| Web Application Firewall | `waf`        | 80         | Alphanumeric, underscore, hyphen, period | `waf-PRD-WEU-001`                  |

### Compute & Web

| Resource Type    | Abbreviation | Max Length           | Allowed Characters                       | Example                          |
|------------------|--------------|----------------------|------------------------------------------|----------------------------------|
| Virtual Machine  | `vm`         | 64 (Win), 15 (Linux) | Alphanumeric, hyphen                     | `vm-PRD-WEU-alpha-001`           |
| VM Scale Set     | `vmss`       | 64 (Win), 15 (Linux) | Alphanumeric, hyphen                     | `vmss-PRD-WEU-web-001`           |
| Availability Set | `avail`      | 80                   | Alphanumeric, underscore, hyphen, period | `avail-PRD-WEU-web-001`          |
| Managed Disk     | `disk`       | 80                   | Alphanumeric, underscore, hyphen, period | `disk-PRD-WEU-vm01-os-001`       |
| Snapshot         | `snap`       | 80                   | Alphanumeric, underscore, hyphen, period | `snap-PRD-WEU-vm01-001`          |
| Image            | `img`        | 80                   | Alphanumeric, underscore, hyphen, period | `img-PRD-WEU-web-001`            |
| App Service Plan | `plan`       | 40                   | Alphanumeric, hyphen                     | `plan-PRD-WEU-web-001`           |
| App Service      | `app`        | 60                   | Alphanumeric, hyphen                     | `app-PRD-WEU-web-001`            |
| Function App     | `func`       | 60                   | Alphanumeric, hyphen                     | `func-PRD-WEU-api-001`           |
| Static Web App   | `stapp`      | 40                   | Alphanumeric, hyphen                     | `stapp-PRD-WEU-001`              |
| Logic App        | `logic`      | 80                   | Alphanumeric, underscore, hyphen, period | `logic-PRD-WEU-001`              |
| Batch Account    | `ba`         | 24                   | Lowercase alphanumeric                   | `baprdweu001`                    |

### Data & Storage

| Resource Type        | Abbreviation | Max Length | Allowed Characters                       | Example                        |
|----------------------|--------------|------------|------------------------------------------|--------------------------------|
| Storage Account      | `st`         | 24         | Lowercase alphanumeric                   | `stprdweu001`                  |
| Storage Container    | `stct`       | 63         | Lowercase alphanumeric, hyphen           | `stct-prd-weu-001`             |
| File Share           | `fs`         | 63         | Lowercase alphanumeric, hyphen           | `fs-prd-weu-001`               |
| Queue                | `stq`        | 63         | Lowercase alphanumeric, hyphen           | `stq-prd-weu-001`              |
| Table                | `stt`        | 63         | Alphanumeric                             | `sttprdweu001`                 |
| SQL Server           | `sql`        | 63         | Lowercase alphanumeric, hyphen           | `sql-PRD-WEU-001`              |
| SQL Database         | `sqldb`      | 128        | Alphanumeric, underscore, hyphen, period | `sqldb-PRD-WEU-main-001`       |
| SQL Elastic Pool     | `sqlep`      | 128        | Alphanumeric, underscore, hyphen, period | `sqlep-PRD-WEU-001`            |
| SQL Managed Instance | `sqlmi`      | 63         | Lowercase alphanumeric, hyphen           | `sqlmi-PRD-WEU-001`            |
| Cosmos DB            | `cosmos`     | 44         | Lowercase alphanumeric, hyphen           | `cosmos-PRD-WEU-001`           |
| Redis Cache          | `redis`      | 63         | Alphanumeric, hyphen                     | `redis-PRD-WEU-001`            |
| MySQL Database       | `mysql`      | 63         | Lowercase alphanumeric, hyphen           | `mysql-PRD-WEU-001`            |
| PostgreSQL Database  | `psql`       | 63         | Lowercase alphanumeric, hyphen           | `psql-PRD-WEU-001`             |
| MariaDB Database     | `mariadb`    | 63         | Lowercase alphanumeric, hyphen           | `mariadb-PRD-WEU-001`          |
| Data Factory         | `adf`        | 63         | Alphanumeric, hyphen                     | `adf-PRD-WEU-001`              |
| Synapse Workspace    | `syn`        | 45         | Alphanumeric, hyphen                     | `syn-PRD-WEU-001`              |
| Analysis Services    | `as`         | 63         | Lowercase alphanumeric                   | `asprdweu001`                  |
| Data Lake Store      | `dls`        | 24         | Lowercase alphanumeric                   | `dlsprdweu001`                 |
| Data Lake Analytics  | `dla`        | 24         | Lowercase alphanumeric                   | `dlaprdweu001`                 |
| HDInsight Cluster    | `hdi`        | 59         | Alphanumeric, hyphen                     | `hdi-PRD-WEU-001`              |
| Power BI Embedded    | `pbi`        | 63         | Alphanumeric, hyphen                     | `pbi-PRD-WEU-001`              |

### Containers & DevOps

| Resource Type          | Abbreviation | Max Length | Allowed Characters                       | Example                        |
|------------------------|--------------|------------|------------------------------------------|--------------------------------|
| Container Registry     | `cr`         | 50         | Alphanumeric                             | `crprdweu001`                  |
| Kubernetes Service     | `aks`        | 63         | Alphanumeric, hyphen                     | `aks-PRD-WEU-001`              |
| Container Instance     | `ci`         | 63         | Lowercase alphanumeric, hyphen           | `ci-PRD-WEU-web-001`           |
| Container App          | `ca`         | 32         | Lowercase alphanumeric, hyphen           | `ca-PRD-WEU-001`               |
| Service Fabric Cluster | `sf`         | 23         | Lowercase alphanumeric                   | `sfprdweu001`                  |
| Service Bus Namespace  | `sb`         | 50         | Alphanumeric, hyphen                     | `sb-PRD-WEU-001`               |
| Service Bus Queue      | `sbq`        | 50         | Alphanumeric, hyphen, underscore, period | `sbq-PRD-WEU-orders-001`       |
| Service Bus Topic      | `sbt`        | 50         | Alphanumeric, hyphen, underscore, period | `sbt-PRD-WEU-events-001`       |
| Event Hub Namespace    | `evhns`      | 50         | Alphanumeric, hyphen                     | `evhns-PRD-WEU-001`            |
| Event Hub              | `evh`        | 50         | Alphanumeric, hyphen, underscore, period | `evh-PRD-WEU-logs-001`         |
| Event Grid Domain      | `egd`        | 50         | Alphanumeric, hyphen                     | `egd-PRD-WEU-001`              |
| Event Grid Topic       | `egt`        | 50         | Alphanumeric, hyphen                     | `egt-PRD-WEU-001`              |
| IoT Hub                | `iot`        | 50         | Alphanumeric, hyphen                     | `iot-PRD-WEU-001`              |
| Notification Hub       | `ntf`        | 260        | Alphanumeric, hyphen                     | `ntf-PRD-WEU-001`              |
| DevTest Lab            | `dtl`        | 50         | Alphanumeric, hyphen                     | `dtl-PRD-WEU-001`              |

### Monitoring & Management

| Resource Type           | Abbreviation | Max Length | Allowed Characters                                    | Example                             |
|-------------------------|--------------|------------|-------------------------------------------------------|-------------------------------------|
| Log Analytics Workspace | `log`        | 63         | Alphanumeric, hyphen                                  | `log-PRD-WEU-001`                   |
| Application Insights    | `appi`       | 260        | Unicode characters                                    | `appi-PRD-WEU-web-001`              |
| Action Group            | `ag`         | 260        | Unicode characters                                    | `ag-PRD-WEU-001`                    |
| Alert Rule              | `ar`         | 260        | Unicode characters                                    | `ar-PRD-WEU-001`                    |
| Recovery Services Vault | `rsv`        | 50         | Alphanumeric, hyphen                                  | `rsv-PRD-WEU-001`                   |
| Backup Vault            | `bv`         | 50         | Alphanumeric, hyphen                                  | `bv-PRD-WEU-001`                    |
| Site Recovery Vault     | `srv`        | 50         | Alphanumeric, hyphen                                  | `srv-PRD-WEU-001`                   |
| Automation Account      | `aa`         | 50         | Alphanumeric, hyphen                                  | `aa-PRD-WEU-001`                    |
| Managed Grafana         | `amg`        | 23         | Alphanumeric, hyphen                                  | `amg-PRD-WEU-001`                   |
| Dashboard               | `dash`       | 160        | Unicode characters                                    | `dash-PRD-WEU-001`                  |
| Workbook                | `wb`         | 260        | Unicode characters                                    | `wb-PRD-WEU-001`                    |
| Policy Definition       | `policy`     | 128        | Unicode characters                                    | `policy-PRD-WEU-deny-pip-001`       |
| Policy Assignment       | `assign`     | 128        | Unicode characters                                    | `assign-PRD-WEU-deny-pip-001`       |
| Blueprint               | `bp`         | 48         | Alphanumeric, hyphen, underscore, period              | `bp-PRD-WEU-001`                    |
| Management Group        | `mg`         | 90         | Alphanumeric, underscore, parentheses, hyphen, period | `mg-PRD-WEU-001`                    |

### AI & Cognitive Services

| Resource Type              | Abbreviation | Max Length | Allowed Characters                       | Example                        |
|----------------------------|--------------|------------|------------------------------------------|--------------------------------|
| Cognitive Services         | `cog`        | 64         | Alphanumeric, underscore, hyphen, period | `cog-PRD-WEU-vision-001`       |
| Computer Vision            | `cv`         | 64         | Alphanumeric, underscore, hyphen, period | `cv-PRD-WEU-001`               |
| Custom Vision              | `cusv`       | 64         | Alphanumeric, underscore, hyphen, period | `cusv-PRD-WEU-001`             |
| Face API                   | `face`       | 64         | Alphanumeric, underscore, hyphen, period | `face-PRD-WEU-001`             |
| Form Recognizer            | `fr`         | 64         | Alphanumeric, underscore, hyphen, period | `fr-PRD-WEU-001`               |
| Language Understanding     | `luis`       | 64         | Alphanumeric, underscore, hyphen, period | `luis-PRD-WEU-001`             |
| QnA Maker                  | `qna`        | 64         | Alphanumeric, underscore, hyphen, period | `qna-PRD-WEU-001`              |
| Speech Service             | `speech`     | 64         | Alphanumeric, underscore, hyphen, period | `speech-PRD-WEU-001`           |
| Text Analytics             | `ta`         | 64         | Alphanumeric, underscore, hyphen, period | `ta-PRD-WEU-001`               |
| Translator                 | `trans`      | 64         | Alphanumeric, underscore, hyphen, period | `trans-PRD-WEU-001`            |
| Bot Service                | `bot`        | 64         | Alphanumeric, underscore, hyphen, period | `bot-PRD-WEU-001`              |
| Machine Learning Workspace | `mlw`        | 260        | Unicode characters                       | `mlw-PRD-WEU-001`              |
| Machine Learning Compute   | `mlc`        | 24         | Alphanumeric, hyphen                     | `mlc-PRD-WEU-001`              |
| Search Service             | `srch`       | 60         | Lowercase alphanumeric, hyphen           | `srch-PRD-WEU-001`             |
| Maps Account               | `map`        | 98         | Alphanumeric, underscore, hyphen, period | `map-PRD-WEU-001`              |

### Integration & API

| Resource Type         | Abbreviation | Max Length | Allowed Characters                       | Example                   |
|-----------------------|--------------|------------|------------------------------------------|---------------------------|
| API Management        | `apim`       | 50         | Alphanumeric, hyphen                     | `apim-PRD-WEU-001`        |
| Logic App             | `logic`      | 80         | Alphanumeric, underscore, hyphen, period | `logic-PRD-WEU-001`       |
| Integration Account   | `ia`         | 80         | Alphanumeric, underscore, hyphen, period | `ia-PRD-WEU-001`          |
| Data Factory          | `df`         | 63         | Alphanumeric, hyphen                     | `df-PRD-WEU-001`          |
| Data Factory Pipeline | `dfp`        | 260        | Alphanumeric, hyphen, underscore, period | `dfp-PRD-WEU-001`         |
| Stream Analytics      | `asa`        | 63         | Alphanumeric, hyphen, underscore         | `asa-PRD-WEU-001`         |
| Power Automate        | `flow`       | 260        | Unicode characters                       | `flow-PRD-WEU-001`        |

### Media & Communication

| Resource Type          | Abbreviation | Max Length | Allowed Characters     | Example                  |
|------------------------|--------------|------------|------------------------|--------------------------|
| Media Services         | `ams`        | 24         | Lowercase alphanumeric | `amsprdweu001`           |
| Communication Services | `acs`        | 63         | Alphanumeric, hyphen   | `acs-PRD-WEU-001`        |
| SignalR Service        | `sigr`       | 63         | Alphanumeric, hyphen   | `sigr-PRD-WEU-001`       |
| Web PubSub             | `wps`        | 63         | Alphanumeric, hyphen   | `wps-PRD-WEU-001`        |

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

#### Step 8: Network Security Groups (But this implementation - NSGs are not used)
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

## Terraform Structure (Updated)

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
│   └── templates/             # Reusable pipeline templates
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
├── scripts/                   # Infrastructure management scripts
│   ├── vm-password-rotation.sh    # Automated VM password rotation
│   ├── cost-analysis.sh           # Cost analysis and optimization
│   ├── health-check.sh            # Infrastructure health monitoring
│   ├── backup-management.sh       # Backup operations and validation
│   ├── environment-cleanup.sh     # Environment cleanup and optimization
│   ├── init.sh                    # Terraform initialization
│   ├── plan.sh                    # Terraform planning
│   ├── apply.sh                   # Terraform apply
│   └── destroy.sh                 # Terraform destroy
├── README.md                  # Main project documentation
├── CONTRIBUTING.md            # Contribution guidelines
├── PIPELINE-SETUP-GUIDE.md    # Complete pipeline implementation guide
└── PROJECT-STRUCTURE.md       # Detailed project structure documentation
```

# TRL Hub-Spoke Azure Infrastructure

This repository contains Terraform Infrastructure as Code (IaC) for deploying a secure hub-and-spoke network architecture on Microsoft Azure. The infrastructure follows Azure naming conventions and best practices for enterprise-grade deployments.

## Architecture Overview

The solution deploys a centralized hub with multiple spoke networks:

- **Hub**: Centralized services including Azure Firewall, Bastion, and shared resources
- **Spoke Alpha**: First spoke network with Windows Server VM and workloads
- **Spoke Beta**: Second spoke network with Windows Server VM and workloads

## Azure Resource Naming Conventions

All resources follow standardized Azure naming conventions:

### Naming Pattern
`{resource-type}-{ENV}-{LOCATION}-{purpose}-{instance}`

### Examples
- **Virtual Machines**: `vm-PRD-WEU-alpha-001`, `vm-DEV-WEU-beta-001`
- **Virtual Networks**: `vnet-PRD-WEU-hub-001`, `vnet-PRD-WEU-alpha-001`
- **Resource Groups**: `rg-trl-PRD-alpha-001`, `RG-TRL-Hub-weu`
- **Storage Accounts**: `stprdweu001`, `stdiagprdweu001`
- **Network Security Groups**: `nsg-PRD-WEU-hub-001`
- **Subnets**: `snet-PRD-WEU-alpha-vm-001`
- **Azure Firewall**: `afw-PRD-WEU-001`
- **Key Vault**: `kv-PRD-WEU-001`
- **SQL Server**: `sql-PRD-WEU-001`
- **Cosmos DB**: `cosmos-PRD-WEU-001`

### Abbreviations Used
- **Environments**: PRD (Production), STG (Staging), DEV (Development)
- **Locations**: WEU (West Europe), EUS (East US), NEU (North Europe)
- **Resource Types**: vm (Virtual Machine), vnet (Virtual Network), rg (Resource Group), st (Storage Account), etc.

## Infrastructure Components

### Hub Resources (RG-TRL-Hub-weu)
- **Azure Firewall**: `afw-PRD-WEU-001` - Centralized network security and routing
- **Azure Bastion**: `bastion-PRD-WEU-001` - Secure RDP/SSH access to VMs
- **Key Vault**: `kv-PRD-WEU-001` - Secure storage for VM passwords and certificates
- **Diagnostics Storage**: `stdiagprdweu001` - Boot diagnostics for all VMs
- **Private DNS Zones**: Internal name resolution

### Spoke Alpha Resources
- **Windows Server VM**: `vm-PRD-WEU-alpha-001` (10.1.4.10)
- **Virtual Network**: `vnet-PRD-WEU-alpha-001` (10.1.0.0/16)
- **Subnets**: VM, workload, database, and private endpoint subnets
- **Storage Account**: `stprdweu001` - Private storage with blob and file shares

### Spoke Beta Resources
- **Windows Server VM**: `vm-PRD-WEU-beta-001` (10.2.4.10)
- **Virtual Network**: `vnet-PRD-WEU-beta-001` (10.2.0.0/16)
- **Subnets**: VM, workload, database, and private endpoint subnets

## Network Architecture

```
Hub VNet (10.0.0.0/16) - vnet-PRD-WEU-hub-001
├── Azure Firewall (10.0.1.0/26) - afw-PRD-WEU-001
├── Azure Bastion (10.0.2.0/27) - bastion-PRD-WEU-001
├── Shared Services (10.0.3.0/24) - snet-PRD-WEU-shared-001
└── Private Endpoints (10.0.4.0/24) - snet-PRD-WEU-pe-hub-001

Spoke Alpha VNet (10.1.0.0/16) - vnet-PRD-WEU-alpha-001
├── VM Subnet (10.1.4.0/24) - snet-PRD-WEU-alpha-vm-001
├── Workload Subnet (10.1.1.0/24) - snet-PRD-WEU-alpha-workload-001
├── Database Subnet (10.1.2.0/24) - snet-PRD-WEU-alpha-db-001
└── Private Endpoints (10.1.3.0/24) - snet-PRD-WEU-alpha-pe-001

Spoke Beta VNet (10.2.0.0/16) - vnet-PRD-WEU-beta-001
├── VM Subnet (10.2.4.0/24) - snet-PRD-WEU-beta-vm-001
├── Workload Subnet (10.2.1.0/24) - snet-PRD-WEU-beta-workload-001
├── Database Subnet (10.2.2.0/24) - snet-PRD-WEU-beta-db-001
└── Private Endpoints (10.2.3.0/24) - snet-PRD-WEU-beta-pe-001
```

## Security Features

- **Zero Trust Network**: All traffic routed through Azure Firewall
- **Network Segmentation**: Separate subnets for different workload types
- **Private Endpoints**: Secure connectivity to Azure PaaS services
- **Azure Bastion**: Secure management access without public IPs on VMs
- **Network Security Groups**: Granular traffic control at subnet level
- **Key Vault Integration**: Secure credential management

## Quick Start

1. **Prerequisites**
   - Azure subscription with Contributor access
   - Terraform 1.5+
   - Azure CLI installed and authenticated

2. **Deploy Infrastructure**
   ```bash
   cd workspaces/hub
   terraform init
   terraform plan
   terraform apply
   ```

3. **Access VMs**
   - Via Azure Bastion: Use Azure Portal
   - Via Firewall: RDP to firewall public IP on port 3389

## Project Structure

```
.
├── modules/                    # Reusable Terraform modules
│   ├── main.tf                # Resource groups and core config
│   ├── network.tf             # VNets, subnets, and peering
│   ├── security.tf            # Firewall, Bastion, NSGs
│   ├── compute.tf             # Virtual machines and extensions
│   ├── storage.tf             # Storage accounts and containers
│   ├── keyvault.tf            # Key Vault and secrets
│   ├── database.tf            # SQL Server and Cosmos DB
│   ├── locals.tf              # Local values and naming
│   ├── variables.tf           # Input variables
│   └── outputs.tf             # Output values
├── workspaces/                # Environment-specific deployments
│   └── hub/                   # Hub workspace (includes spokes)
├── pipelines/                 # Azure DevOps CI/CD pipelines
└── scripts/                   # Utility scripts
```

## Cost Optimization

- Uses Standard_B1s VMs (Azure Free Tier eligible)
- LRS storage replication for cost efficiency
- Auto-shutdown enabled for VMs
- Minimal firewall rules for reduced processing costs

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to this project.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
