# Pipeline Variables Guide

This guide describes each pipeline variable, including its purpose, expected data type, valid values/ranges, default value, and example usage.

| Variable Name                  | Description                                                    | Data Type | Valid Values / Range                        | Default Value   | Example Usage                        |
|--------------------------------|----------------------------------------------------------------|-----------|---------------------------------------------|-----------------|--------------------------------------|
| enable_firewall                | Enables or disables deployment of a network firewall.          | boolean   | true, false                                 | false           | `enable_firewall: true`              |
| enable_bastion                 | Toggles deployment of Azure Bastion host for secure VM access. | boolean   | true, false                                 | false           | `enable_bastion: false`              |
| enable_monitoring              | Enables monitoring resources (e.g., Log Analytics, alerts).    | boolean   | true, false                                 | true            | `enable_monitoring: true`            |
| vm_size                        | Specifies the size of deployed virtual machines.               | string    | e.g., Standard_DS1_v2, Standard_B2s         | Standard_DS1_v2 | `vm_size: Standard_B2s`              |
| storage_account_tier           | Sets the performance tier for storage accounts.                | string    | Standard, Premium                           | Standard        | `storage_account_tier: Premium`      |
| log_retention_days             | Number of days to retain logs.                                 | integer   | 1-365                                       | 30              | `log_retention_days: 90`             |
| vpn_gateway_sku                | SKU for VPN Gateway.                                           | string    | Basic, VpnGw1, VpnGw2, VpnGw3               | VpnGw1          | `vpn_gateway_sku: VpnGw2`            |
| app_gateway_sku_name           | SKU name for Application Gateway.                              | string    | Standard_Small, Standard_Medium, WAF_Medium | Standard_Medium | `app_gateway_sku_name: WAF_Medium`   |
| sql_database_sku               | SKU for SQL Database.                                          | string    | Basic, S0, S1, S2, P1, P2                   | S0              | `sql_database_sku: S2`               |
| cpu_alert_threshold            | CPU usage percentage to trigger alert.                         | integer   | 1-100                                       | 80              | `cpu_alert_threshold: 90`            |
| storage_availability_threshold | Storage availability percentage to trigger alert.              | integer   | 1-100                                       | 95              | `storage_availability_threshold: 90` |



## Overview

Variables in this project are organized into **Variable Groups** in Azure DevOps Library. Each variable group contains related configuration values that are used across different pipelines and environments.

### Variable Group Naming Convention

```
<purpose>-<workspace>-<environment>
```

Examples:
- `terraform-backend-dev`
- `azure-credentials-prod`
- `terraform-vars-hub-dev`
- `terraform-vars-spoke-int`

## Variable Groups Structure

### Hub Workspace Variable Groups

| Variable Group            | Purpose                       | Used By           |
|---------------------------|-------------------------------|-------------------|
| `terraform-backend-dev`   | Backend storage configuration | Hub Dev pipeline  |
| `terraform-backend-int`   | Backend storage configuration | Hub Int pipeline  |
| `terraform-backend-prod`  | Backend storage configuration | Hub Prod pipeline |
| `azure-credentials-dev`   | Azure authentication          | Hub Dev pipeline  |
| `azure-credentials-int`   | Azure authentication          | Hub Int pipeline  |
| `azure-credentials-prod`  | Azure authentication          | Hub Prod pipeline |
| `terraform-vars-hub-dev`  | Hub-specific variables        | Hub Dev pipeline  |
| `terraform-vars-hub-int`  | Hub-specific variables        | Hub Int pipeline  |
| `terraform-vars-hub-prod` | Hub-specific variables        | Hub Prod pipeline |

### Spoke Workspace Variable Groups

| Variable Group              | Purpose              | Used By             |
|-----------------------------|----------------------|---------------------|
| `terraform-vars-spoke-dev`  | Dev spoke variables  | Dev spoke pipeline  |
| `terraform-vars-spoke-int`  | Int spoke variables  | Int spoke pipeline  |
| `terraform-vars-spoke-prod` | Prod spoke variables | Prod spoke pipeline |

### Management Workspace Variable Groups

| Variable Group             | Purpose                        | Used By             |
|----------------------------|--------------------------------|---------------------|
| `terraform-vars-mgmt-prod` | Management workspace variables | Management pipeline |

## Backend Configuration Variables

These variables configure the Terraform remote state backend using Azure Storage.

### Variable Group: `terraform-backend-<env>`

| Variable Name               | Description                             | Example                      | Required | Secret |
|-----------------------------|-----------------------------------------|------------------------------|----------|--------|
| `backendResourceGroupName`  | Resource group containing state storage | `rg-terraform-state-dev`     | ✅ Yes    | No     |
| `backendStorageAccountName` | Storage account for Terraform state     | `sttfstatedevweu123456`      | ✅ Yes    | No     |
| `backendContainerName`      | Container name for state files          | `tfstate`                    | ✅ Yes    | No     |
| `backendKey`                | State file name (workspace-specific)    | `hub.tfstate`, `dev.tfstate` | ✅ Yes    | No     |

### Configuration Details

#### backendResourceGroupName
- **Purpose**: Identifies the resource group containing the backend storage account
- **Format**: `rg-terraform-state-<environment>`
- **Valid Values**: Any valid Azure resource group name
- **Example**:
  - Dev: `rg-terraform-state-dev`
  - Int: `rg-terraform-state-int`
  - Prod: `rg-terraform-state-prod`

#### backendStorageAccountName
- **Purpose**: Name of the storage account holding Terraform state files
- **Format**: `st<purpose><env><location><random>`
- **Constraints**: 
  - 3-24 characters
  - Lowercase letters and numbers only
  - Globally unique
- **Example**: `sttfstatedevweu7h2k9p`

#### backendContainerName
- **Purpose**: Container within storage account for state files
- **Standard Value**: `tfstate`
- **Note**: Typically the same across environments

#### backendKey
- **Purpose**: Name of the state file for this workspace
- **Format**: `<workspace>.tfstate`
- **Examples**:
  - Hub: `hub.tfstate`
  - Dev spoke: `dev.tfstate`
  - Int spoke: `int.tfstate`
  - Prod spoke: `prod.tfstate`
  - Management: `management.tfstate`

### Setup Instructions

Create backend storage for each environment:

```bash
# Set environment variables
ENVIRONMENT="dev"
LOCATION="westeurope"
RANDOM_SUFFIX=$(openssl rand -hex 3)

# Create resource group
az group create \
  --name "rg-terraform-state-${ENVIRONMENT}" \
  --location "${LOCATION}"

# Create storage account
az storage account create \
  --name "sttfstate${ENVIRONMENT}weu${RANDOM_SUFFIX}" \
  --resource-group "rg-terraform-state-${ENVIRONMENT}" \
  --location "${LOCATION}" \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2

# Create container
az storage container create \
  --name tfstate \
  --account-name "sttfstate${ENVIRONMENT}weu${RANDOM_SUFFIX}"
```

## Azure Credentials Variables

These variables provide authentication to Azure for Terraform operations.

### Variable Group: `azure-credentials-<env>`

| Variable Name         | Description                       | Example                                | Required | Secret    |
|-----------------------|-----------------------------------|----------------------------------------|----------|-----------|
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID             | `12345678-1234-1234-1234-123456789012` | ✅ Yes    | No        |
| `ARM_TENANT_ID`       | Azure Active Directory tenant ID  | `87654321-4321-4321-4321-210987654321` | ✅ Yes    | No        |
| `ARM_CLIENT_ID`       | Service principal application ID  | `abcdef12-3456-7890-abcd-ef1234567890` | ✅ Yes    | No        |
| `ARM_CLIENT_SECRET`   | Service principal password/secret | `your-secret-value`                    | ✅ Yes    | ✅ **Yes** |

### Configuration Details

#### ARM_SUBSCRIPTION_ID
- **Purpose**: Specifies which Azure subscription to deploy resources into
- **Format**: GUID (8-4-4-4-12 format)
- **How to Get**:
  ```bash
  az account show --query id --output tsv
  ```

#### ARM_TENANT_ID
- **Purpose**: Identifies the Azure AD tenant
- **Format**: GUID
- **How to Get**:
  ```bash
  az account show --query tenantId --output tsv
  ```

#### ARM_CLIENT_ID
- **Purpose**: Application ID of the service principal
- **Format**: GUID
- **How to Get**: Provided when creating service principal

#### ARM_CLIENT_SECRET
- **Purpose**: Secret key for service principal authentication
- **Format**: String
- **Security**: 
  - ⚠️ **MUST be marked as secret** in Azure DevOps
  - Never commit to source control
  - Rotate regularly (every 90 days recommended)
  - Use Azure Key Vault for production

### Service Principal Creation

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "sp-terraform-${ENVIRONMENT}" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>

# Output will include:
# - appId (use for ARM_CLIENT_ID)
# - password (use for ARM_CLIENT_SECRET)
# - tenant (use for ARM_TENANT_ID)
```

## Core Infrastructure Variables

These variables define the fundamental configuration of the infrastructure.

### Variable Group: `terraform-vars-<workspace>-<env>`

| Variable Name        | Description             | Type   | Default        | Required |
|----------------------|-------------------------|--------|----------------|----------|
| `subscription_id`    | Azure subscription ID   | string | -              | ✅ Yes    |
| `environment`        | Environment name        | string | -              | ✅ Yes    |
| `location`           | Primary Azure region    | string | `West Europe`  | ✅ Yes    |
| `location_secondary` | Secondary region for DR | string | `North Europe` | No       |

### Configuration Details

#### subscription_id
- **Purpose**: Azure subscription for resource deployment
- **Valid Values**: Valid Azure subscription GUID
- **Example**: `12345678-1234-1234-1234-123456789012`
- **Note**: Usually same as `ARM_SUBSCRIPTION_ID`

#### environment
- **Purpose**: Identifies the deployment environment
- **Valid Values**: `dev`, `int`, `prod`
- **Validation**: Must be one of the three valid values
- **Impact**: 
  - Affects resource naming (dev, int, prd abbreviations)
  - Determines default configurations
  - Influences tagging

#### location
- **Purpose**: Primary Azure region for resource deployment
- **Valid Values**: Any valid Azure region
- **Common Values**:
  - `West Europe`
  - `North Europe`
  - `East US`
  - `East US 2`
  - `UK South`
- **Impact**: 
  - Affects resource naming (location abbreviations)
  - Determines data residency
  - Influences pricing

#### location_secondary
- **Purpose**: Secondary region for geo-redundancy and disaster recovery
- **Valid Values**: Any valid Azure region (different from primary)
- **Default**: `North Europe`
- **Use Cases**:
  - Geo-redundant storage
  - Traffic Manager endpoints
  - DR failover targets

## Network Configuration Variables

These variables control the network topology and security.

### Variable Group: `terraform-vars-<workspace>-<env>`

| Variable Name                 | Description                  | Type   | Default       | Required |
|-------------------------------|------------------------------|--------|---------------|----------|
| `enable_firewall`             | Enable Azure Firewall        | bool   | `false`       | No       |
| `enable_bastion`              | Enable Azure Bastion         | bool   | `false`       | No       |
| `enable_private_dns`          | Enable Private DNS zones     | bool   | `true`        | No       |
| `enable_ddos_protection`      | Enable DDoS Protection Plan  | bool   | `false`       | No       |
| `enable_private_endpoints`    | Enable private endpoints     | bool   | `true`        | No       |
| `spoke_count`                 | Number of spoke networks     | number | `1`           | No       |
| `enable_vpn_gateway`          | Enable VPN Gateway           | bool   | `false`       | No       |
| `vpn_gateway_sku`             | VPN Gateway SKU              | string | `VpnGw1`      | No       |
| `enable_expressroute_gateway` | Enable ExpressRoute Gateway  | bool   | `false`       | No       |
| `expressroute_gateway_sku`    | ExpressRoute Gateway SKU     | string | `Standard`    | No       |
| `enable_app_gateway`          | Enable Application Gateway   | bool   | `false`       | No       |
| `app_gateway_sku_name`        | Application Gateway SKU      | string | `Standard_v2` | No       |
| `app_gateway_capacity`        | Application Gateway capacity | number | `2`           | No       |

### Configuration Details

#### enable_firewall
- **Purpose**: Deploy Azure Firewall in hub network
- **Valid Values**: `true`, `false`
- **Default**: `false`
- **Cost Impact**: ~$1.25/hour when enabled
- **Recommendations**:
  - Dev: `false`
  - Int: `true` (if testing security)
  - Prod: `true`

#### enable_bastion
- **Purpose**: Deploy Azure Bastion for secure VM access
- **Valid Values**: `true`, `false`
- **Default**: `false`
- **Cost Impact**: ~$0.19/hour
- **Recommendations**:
  - Dev: `true` (for development access)
  - Int: `true`
  - Prod: `true`

#### enable_private_dns
- **Purpose**: Create Private DNS zones for Azure services
- **Valid Values**: `true`, `false`
- **Default**: `true`
- **Use Cases**:
  - Private endpoint name resolution
  - Internal service discovery
  - Hybrid connectivity

#### enable_ddos_protection
- **Purpose**: Enable Azure DDoS Protection Standard
- **Valid Values**: `true`, `false`
- **Default**: `false`
- **Cost Impact**: ~$2,944/month
- **Recommendations**:
  - Dev: `false`
  - Int: `false`
  - Prod: `true` (for public-facing workloads)

#### spoke_count
- **Purpose**: Number of spoke virtual networks to create
- **Valid Values**: `0` to `3`
- **Default**: `1`
- **Impact**:
  - Creates spoke VNets with appropriate subnets
  - Establishes VNet peering with hub
  - Deploys spoke-specific resources
- **Spoke Names**:
  - 1: Alpha
  - 2: Beta
  - 3: Gamma

#### enable_vpn_gateway
- **Purpose**: Deploy VPN Gateway for site-to-site connectivity
- **Valid Values**: `true`, `false`
- **Default**: `false`
- **Prerequisites**: Gateway subnet created in hub
- **Cost Impact**: Varies by SKU (~$0.19/hour for VpnGw1)

#### vpn_gateway_sku
- **Purpose**: VPN Gateway performance tier
- **Valid Values**: `VpnGw1`, `VpnGw2`, `VpnGw3`, `VpnGw4`, `VpnGw5`
- **Default**: `VpnGw1`
- **Considerations**:
  - VpnGw1: Up to 650 Mbps, 30 tunnels
  - VpnGw2: Up to 1 Gbps, 30 tunnels
  - VpnGw3: Up to 1.25 Gbps, 30 tunnels

## Compute Configuration Variables

These variables control virtual machine deployments.

### Variable Group: `terraform-vars-<workspace>-<env>`

| Variable Name                     | Description               | Type   | Default        | Required |
|-----------------------------------|---------------------------|--------|----------------|----------|
| `vm_size`                         | Virtual machine SKU       | string | `Standard_B2s` | No       |
| `admin_username`                  | VM administrator username | string | `azureuser`    | No       |
| `admin_password`                  | VM administrator password | string | -              | ✅ Yes    |
| `enable_vm_auto_shutdown`         | Enable auto-shutdown      | bool   | `false`        | No       |
| `vm_shutdown_time`                | Auto-shutdown time (UTC)  | string | `1900`         | No       |
| `enable_vm_monitoring`            | Enable VM monitoring      | bool   | `true`         | No       |
| `vm_cpu_alert_threshold`          | CPU alert threshold (%)   | number | `80`           | No       |
| `vm_memory_alert_threshold_bytes` | Memory alert threshold    | number | `1073741824`   | No       |

### Configuration Details

#### vm_size
- **Purpose**: Determines VM performance and cost
- **Valid Values**: Any valid Azure VM size
- **Common Values**:
  - **Dev**: `Standard_B1s`, `Standard_B2s` (cost-effective)
  - **Int**: `Standard_D2s_v3`, `Standard_D4s_v3` (balanced)
  - **Prod**: `Standard_D4s_v5`, `Standard_E4s_v5` (performance)
- **Considerations**:
  - B-series: Burstable, cost-effective for development
  - D-series: General purpose, balanced compute/memory
  - E-series: Memory-optimized

#### admin_username
- **Purpose**: Default administrator account name
- **Valid Values**: String, 1-64 characters
- **Restrictions**:
  - Cannot be common names (admin, root, etc.)
  - Cannot contain special characters
- **Default**: `azureuser`
- **Security**: Avoid default values in production

#### admin_password
- **Purpose**: Administrator account password
- **Valid Values**: String, 12-123 characters
- **Requirements**:
  - At least 3 of: lowercase, uppercase, numbers, special characters
  - Cannot contain username
- **Security**: 
  - ⚠️ **MUST be marked as secret**
  - Use complex passwords
  - Consider Azure Key Vault
  - Rotate regularly

#### enable_vm_auto_shutdown
- **Purpose**: Automatically shut down VMs to save costs
- **Valid Values**: `true`, `false`
- **Default**: `false`
- **Recommendations**:
  - Dev: `true` (shutdown at 7 PM)
  - Int: `true` (shutdown at 9 PM)
  - Prod: `false`

#### vm_shutdown_time
- **Purpose**: Time for auto-shutdown in 24-hour format (UTC)
- **Valid Values**: `0000` to `2359`
- **Default**: `1900` (7 PM UTC)
- **Examples**:
  - `1900` = 7:00 PM UTC
  - `2100` = 9:00 PM UTC
  - `0200` = 2:00 AM UTC

## Storage Configuration Variables

These variables control storage account deployments.

### Variable Group: `terraform-vars-<workspace>-<env>`

| Variable Name                    | Description              | Type   | Default    | Required |
|----------------------------------|--------------------------|--------|------------|----------|
| `storage_account_tier`           | Storage account tier     | string | `Standard` | No       |
| `storage_replication_type`       | Replication strategy     | string | `LRS`      | No       |
| `storage_availability_threshold` | Availability alert (%)   | number | `99`       | No       |
| `enable_data_lake`               | Enable Data Lake Storage | bool   | `false`    | No       |
| `data_lake_replication_type`     | Data Lake replication    | string | `LRS`      | No       |
| `enable_storage_sync`            | Enable Azure File Sync   | bool   | `false`    | No       |
| `enable_premium_storage`         | Enable Premium storage   | bool   | `false`    | No       |

### Configuration Details

#### storage_account_tier
- **Purpose**: Storage performance tier
- **Valid Values**: `Standard`, `Premium`
- **Default**: `Standard`
- **Recommendations**:
  - Dev: `Standard`
  - Int: `Standard`
  - Prod: `Standard` or `Premium` (based on workload)

#### storage_replication_type
- **Purpose**: Data redundancy strategy
- **Valid Values**:
  - `LRS`: Locally redundant storage (3 copies in one datacenter)
  - `GRS`: Geo-redundant storage (6 copies across two regions)
  - `RAGRS`: Read-access geo-redundant storage
  - `ZRS`: Zone-redundant storage (3 copies across availability zones)
  - `GZRS`: Geo-zone-redundant storage
- **Default**: `LRS`
- **Recommendations**:
  - Dev: `LRS` (cost-effective)
  - Int: `LRS` or `ZRS`
  - Prod: `GRS` or `GZRS` (critical data)

#### enable_data_lake
- **Purpose**: Enable hierarchical namespace for analytics
- **Valid Values**: `true`, `false`
- **Default**: `false`
- **Use Cases**:
  - Big data analytics
  - Data lake architectures
  - Hadoop/Spark workloads
- **Note**: Cannot be changed after creation

## Database Configuration Variables

These variables control database service deployments.

### Variable Group: `terraform-vars-<workspace>-<env>`

| Variable Name                 | Description               | Type   | Default           | Required |
|-------------------------------|---------------------------|--------|-------------------|----------|
| `enable_sql_database`         | Enable Azure SQL Database | bool   | `false`           | No       |
| `sql_server_version`          | SQL Server version        | string | `12.0`            | No       |
| `sql_database_sku`            | Database SKU              | string | `Basic`           | No       |
| `enable_cosmos_db`            | Enable Cosmos DB          | bool   | `false`           | No       |
| `cosmos_db_consistency_level` | Consistency level         | string | `Session`         | No       |
| `enable_postgresql`           | Enable PostgreSQL         | bool   | `false`           | No       |
| `postgresql_sku_name`         | PostgreSQL SKU            | string | `B_Standard_B1ms` | No       |

### Configuration Details

#### enable_sql_database
- **Purpose**: Deploy Azure SQL Database
- **Valid Values**: `true`, `false`
- **Default**: `false`
- **Cost Impact**: Varies by SKU

#### sql_database_sku
- **Purpose**: SQL Database performance tier
- **Valid Values**:
  - `Basic`: 5 DTUs, up to 2 GB
  - `S0`, `S1`, `S2`: Standard tier
  - `P1`, `P2`, `P4`: Premium tier
  - `GP_Gen5_2`, `GP_Gen5_4`: General Purpose vCore
- **Recommendations**:
  - Dev: `Basic` or `S0`
  - Int: `S1` or `S2`
  - Prod: `P1` or vCore-based

#### enable_cosmos_db
- **Purpose**: Deploy Cosmos DB account
- **Valid Values**: `true`, `false`
- **Default**: `false`
- **Use Cases**:
  - NoSQL database needs
  - Global distribution
  - Multi-model data

#### cosmos_db_consistency_level
- **Purpose**: Data consistency guarantee
- **Valid Values**:
  - `Eventual`: Lowest latency, eventual consistency
  - `Session`: Default, consistent within session
  - `BoundedStaleness`: Configurable lag
  - `Strong`: Highest consistency, higher latency
  - `ConsistentPrefix`: Reads never see out-of-order writes
- **Default**: `Session`

## Security Configuration Variables

These variables control security resources.

### Variable Group: `terraform-vars-<workspace>-<env>`

| Variable Name                  | Description            | Type   | Default    | Required |
|--------------------------------|------------------------|--------|------------|----------|
| `enable_key_vault`             | Enable Azure Key Vault | bool   | `true`     | No       |
| `enable_key_vault_soft_delete` | Enable soft delete     | bool   | `true`     | No       |
| `key_vault_sku_name`           | Key Vault SKU          | string | `standard` | No       |
| `enable_security_center`       | Enable Security Center | bool   | `false`    | No       |
| `security_center_tier`         | Security Center tier   | string | `Free`     | No       |

### Configuration Details

#### enable_key_vault
- **Purpose**: Deploy Azure Key Vault for secrets management
- **Valid Values**: `true`, `false`
- **Default**: `true`
- **Recommendations**: Always `true` for production
- **Use Cases**:
  - Store connection strings
  - Manage certificates
  - Store encryption keys

#### enable_key_vault_soft_delete
- **Purpose**: Protect against accidental deletion
- **Valid Values**: `true`, `false`
- **Default**: `true`
- **Retention**: 90 days
- **Note**: Cannot be disabled once enabled

#### key_vault_sku_name
- **Purpose**: Key Vault pricing tier
- **Valid Values**: `standard`, `premium`
- **Default**: `standard`
- **Premium Features**:
  - HSM-backed keys
  - Enhanced security

## Monitoring and Alerting Variables

These variables control monitoring configuration.

### Variable Group: `terraform-vars-<workspace>-<env>`

| Variable Name                  | Description                | Type         | Default      | Required |
|--------------------------------|----------------------------|--------------|--------------|----------|
| `enable_monitoring`            | Enable monitoring          | bool         | `true`       | No       |
| `log_retention_days`           | Log retention period       | number       | `30`         | No       |
| `log_analytics_sku`            | Log Analytics SKU          | string       | `PerGB2018`  | No       |
| `log_analytics_daily_quota_gb` | Daily ingestion limit (GB) | number       | `10`         | No       |
| `app_insights_retention_days`  | App Insights retention     | number       | `90`         | No       |
| `enable_monitoring_dashboard`  | Enable dashboard           | bool         | `true`       | No       |
| `enable_infrastructure_alerts` | Enable infra alerts        | bool         | `true`       | No       |
| `alert_email_addresses`        | Alert recipients           | list(string) | `[]`         | No       |
| `cpu_alert_threshold`          | CPU alert threshold (%)    | number       | `80`         | No       |
| `memory_alert_threshold_bytes` | Memory threshold           | number       | `1073741824` | No       |
| `enable_security_alerts`       | Enable security alerts     | bool         | `true`       | No       |

### Configuration Details

#### enable_monitoring
- **Purpose**: Deploy Log Analytics and monitoring
- **Valid Values**: `true`, `false`
- **Default**: `true`
- **Recommendations**: Always `true` for all environments

#### log_retention_days
- **Purpose**: How long to keep log data
- **Valid Values**: `30` to `730` days
- **Default**: `30`
- **Recommendations**:
  - Dev: `30` days
  - Int: `60` days
  - Prod: `90` to `365` days
- **Compliance**: Consider regulatory requirements

#### log_analytics_daily_quota_gb
- **Purpose**: Cap daily data ingestion to control costs
- **Valid Values**: `-1` (unlimited) or positive number
- **Default**: `10`
- **Cost Management**:
  - Monitor actual usage
  - Set appropriate limits
  - Alert when approaching quota

#### alert_email_addresses
- **Purpose**: Recipients for monitoring alerts
- **Valid Values**: List of email addresses
- **Format**: `["user1@company.com", "user2@company.com"]`
- **Example**:
  ```
  ["infrastructure@company.com", "ops-team@company.com"]
  ```

## Tag Variables

These variables control resource tagging for organization and cost management.

### Variable Group: `terraform-vars-<workspace>-<env>`

| Variable Name             | Description           | Type         | Default           | Required |
|---------------------------|-----------------------|--------------|-------------------|----------|
| `created_by`              | Resource creator      | string       | `Terraform`       | No       |
| `service_provider`        | Service provider name | string       | `Internal IT`     | No       |
| `cost_center`             | Cost center code      | string       | -                 | No       |
| `business_unit`           | Business unit         | string       | -                 | No       |
| `project_name`            | Project name          | string       | `Azure Hub-Spoke` | No       |
| `owner_email`             | Resource owner email  | string       | -                 | No       |
| `data_classification`     | Data sensitivity      | string       | `Internal`        | No       |
| `compliance_requirements` | Compliance tags       | list(string) | `[]`              | No       |
| `backup_required`         | Backup requirement    | bool         | `true`            | No       |

### Configuration Details

#### created_by
- **Purpose**: Identifies who/what created the resource
- **Valid Values**: Any string
- **Default**: `Terraform`
- **Examples**: `Terraform`, `DevOps Pipeline`, `John Doe`

#### cost_center
- **Purpose**: Billing and chargeback
- **Valid Values**: Your organization's cost center codes
- **Format**: Alphanumeric, often with hyphens
- **Example**: `IT-INFRA-001`, `CC-12345`

#### owner_email
- **Purpose**: Contact for resource questions
- **Valid Values**: Valid email address
- **Example**: `infrastructure-team@company.com`

#### data_classification
- **Purpose**: Data sensitivity level
- **Valid Values**: `Public`, `Internal`, `Confidential`, `Restricted`
- **Default**: `Internal`
- **Impact**: Influences security controls

#### compliance_requirements
- **Purpose**: Applicable compliance frameworks
- **Valid Values**: List of frameworks
- **Examples**:
  ```
  ["GDPR", "ISO27001"]
  ["HIPAA", "SOC2"]
  ["PCI-DSS"]
  ```

## Environment-Specific Configurations

### Development Environment

```yaml
# terraform-vars-hub-dev
environment: dev
location: West Europe
spoke_count: 1
enable_firewall: false
enable_bastion: true
vm_size: Standard_B1s
storage_replication_type: LRS
enable_sql_database: false
enable_monitoring: true
log_retention_days: 30
enable_vm_auto_shutdown: true
vm_shutdown_time: "1900"
```

### Integration Environment

```yaml
# terraform-vars-hub-int
environment: int
location: West Europe
spoke_count: 2
enable_firewall: true
enable_bastion: true
vm_size: Standard_D2s_v3
storage_replication_type: ZRS
enable_sql_database: true
sql_database_sku: S1
enable_monitoring: true
log_retention_days: 60
enable_vm_auto_shutdown: true
vm_shutdown_time: "2100"
```

### Production Environment

```yaml
# terraform-vars-hub-prod
environment: prod
location: West Europe
spoke_count: 3
enable_firewall: true
enable_bastion: true
enable_ddos_protection: true
vm_size: Standard_D4s_v5
storage_replication_type: GRS
enable_sql_database: true
sql_database_sku: P1
enable_cosmos_db: true
enable_monitoring: true
log_retention_days: 365
enable_vm_auto_shutdown: false
enable_security_alerts: true
alert_email_addresses:
  - "ops@company.com"
  - "security@company.com"
```

## Variable Naming Conventions

### Guidelines

1. **Use snake_case**: `enable_firewall`, not `EnableFirewall`
2. **Be descriptive**: `vm_size`, not `size`
3. **Use prefixes for grouping**:
   - `enable_*`: Boolean feature flags
   - `*_sku`: SKU specifications
   - `*_threshold`: Alert thresholds
4. **Avoid abbreviations** unless common: `database` not `db` (except in resource names)



### Sensitive Variables

Mark the following as **SECRET** in Azure DevOps:

- `ARM_CLIENT_SECRET`
- `admin_password`
- Any database passwords
- API keys or tokens
- Connection strings

### Azure Key Vault Integration

For production, store sensitive values in Key Vault:

1. Create Key Vault:
   ```bash
   az keyvault create \
     --name kv-terraform-prod \
     --resource-group rg-devops-shared \
     --location westeurope
   ```

2. Store secrets:
   ```bash
   az keyvault secret set \
     --vault-name kv-terraform-prod \
     --name vm-admin-password \
     --value "YourSecurePassword123!"
   ```

3. Link to variable group in Azure DevOps:
   - Edit variable group
   - Toggle "Link secrets from an Azure key vault"
   - Select Key Vault and secrets

### Variable Access Control

1. **Restrict variable group access**:
   - Navigate to Library → Variable Group
   - Click "..." → Security
   - Grant access only to necessary users/groups

2. **Use separate groups per environment**:
   - Prevents dev credentials from accessing prod
   - Allows different permission levels

3. **Audit access regularly**:
   - Review who has access
   - Remove unnecessary permissions
   - Track changes via audit logs

### Password Requirements

For `admin_password` and similar:

- Minimum 12 characters
- Include: uppercase, lowercase, numbers, special characters
- Avoid dictionary words
- Use password manager for generation
- Rotate every 90 days
- Never commit to source control

## Validation and Testing

### Variable Validation

Test variables before deployment:

```bash
# In workspaces/hub/variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "int", "prod"], var.environment)
    error_message = "Environment must be dev, int, or prod."
  }
}

variable "spoke_count" {
  description = "Number of spokes"
  type        = number
  
  validation {
    condition     = var.spoke_count >= 0 && var.spoke_count <= 3
    error_message = "Spoke count must be between 0 and 3."
  }
}
```

### Testing Checklist

Before running pipeline:

- [ ] All required variables defined
- [ ] Sensitive variables marked as secret
- [ ] Values appropriate for environment
- [ ] Validation rules satisfied
- [ ] Variable groups linked to pipeline
- [ ] Service connection configured
- [ ] Backend storage accessible

## Troubleshooting

### Variable Not Found

**Error**: `Variable 'xxx' is not defined`

**Solution**:
1. Check variable name spelling
2. Ensure variable group is linked in pipeline YAML
3. Verify variable exists in the correct group

### Type Mismatch

**Error**: `Invalid value for variable "xxx"`

**Solution**:
1. Check variable type in `variables.tf`
2. Ensure value matches expected type:
   - bool: `true` or `false` (not quoted)
   - number: `80` (not quoted)
   - string: `"value"` (quoted in YAML)
   - list: `["item1", "item2"]`

### Access Denied

**Error**: `Permission denied accessing variable group`

**Solution**:
1. Check variable group permissions
2. Ensure pipeline has access
3. Verify service connection permissions

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure DevOps Variable Groups](https://docs.microsoft.com/azure/devops/pipelines/library/variable-groups)
- [Azure Naming Conventions](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [PIPELINE-SETUP-GUIDE.md](PIPELINE-SETUP-GUIDE.md)
- [PIPELINE-DEPLOYMENT-GUIDE.md](PIPELINE-DEPLOYMENT-GUIDE.md)

