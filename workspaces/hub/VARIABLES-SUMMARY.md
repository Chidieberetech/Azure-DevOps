# Hub Workspace Variables Summary

This document provides a comprehensive overview of all variables configured for the Hub workspace.

## Table of Contents
- [Core Configuration](#core-configuration)
- [Network Configuration](#network-configuration)
- [Spoke Configuration](#spoke-configuration)
- [Compute Configuration](#compute-configuration)
- [Security Configuration](#security-configuration)
- [Database Configuration](#database-configuration)
- [Storage Configuration](#storage-configuration)
- [Private Endpoints](#private-endpoints)
- [Monitoring Configuration](#monitoring-configuration)
- [Alerting Configuration](#alerting-configuration)
- [Tagging Configuration](#tagging-configuration)

---

## Core Configuration

| Variable          | Type   | Default         | Description                            |
|-------------------|--------|-----------------|----------------------------------------|
| `subscription_id` | string | **Required**    | Azure subscription ID                  |
| `environment`     | string | `"prod"`        | Environment name (dev, int, prod)      |
| `location`        | string | `"West Europe"` | Primary Azure region for hub resources |

---

## Network Configuration

| Variable                   | Type | Default | Description                           |
|----------------------------|------|---------|---------------------------------------|
| `enable_firewall`          | bool | `true`  | Enable Azure Firewall in the hub      |
| `enable_bastion`           | bool | `true`  | Enable Azure Bastion in the hub       |
| `enable_private_dns`       | bool | `true`  | Enable private DNS zones in the hub   |
| `enable_ddos_protection`   | bool | `false` | Enable DDoS Protection Plan           |
| `enable_private_endpoints` | bool | `true`  | Enable private endpoints for services |

---

## Spoke Configuration

| Variable      | Type   | Default | Description                              |
|---------------|--------|---------|------------------------------------------|
| `spoke_count` | number | `2`     | Number of spoke networks to create (0-3) |

---

## Compute Configuration

| Variable                  | Type   | Default          | Description                                                                   |
|---------------------------|--------|------------------|-------------------------------------------------------------------------------|
| `vm_size`                 | string | `"Standard_B1s"` | Size of the virtual machines                                                  |
| `admin_username`          | string | `"azureadmin"`   | Admin username for VMs (sensitive) It can be differnt. this is a placeholder. |
| `enable_vm_auto_shutdown` | bool   | `true`           | Enable automatic VM shutdown for cost optimization                            |
| `vm_shutdown_time`        | string | `"1900"`         | Time to automatically shutdown VMs (24-hour format)                           |
| `enable_vm_monitoring`    | bool   | `true`           | Enable VM Insights monitoring                                                 |

---

## Security Configuration

| Variable                       | Type | Default | Description                       |
|--------------------------------|------|---------|-----------------------------------|
| `enable_key_vault`             | bool | `true`  | Enable Azure Key Vault in the hub |
| `enable_key_vault_soft_delete` | bool | `true`  | Enable Key Vault soft delete      |

---

## Database Configuration

| Variable              | Type | Default | Description                    |
|-----------------------|------|---------|--------------------------------|
| `enable_sql_database` | bool | `false` | Enable SQL Database deployment |
| `enable_cosmos_db`    | bool | `false` | Enable Cosmos DB deployment    |

---

## Storage Configuration

| Variable                   | Type   | Default      | Description                                          |
|----------------------------|--------|--------------|------------------------------------------------------|
| `storage_account_tier`     | string | `"Standard"` | Storage account tier (Standard, Premium)             |
| `storage_replication_type` | string | `"LRS"`      | Storage replication type (LRS, GRS, RAGRS, ZRS)      |
| `enable_premium_storage`   | bool   | `false`      | Enable premium storage account                       |
| `enable_data_lake_storage` | bool   | `false`      | Enable Data Lake Storage Gen2  (can differ for SFTP) |

---

## Private Endpoints

| Variable                   | Type | Default | Description                           |
|----------------------------|------|---------|---------------------------------------|
| `enable_private_endpoints` | bool | `true`  | Enable private endpoints for services |

---

## Monitoring Configuration

| Variable                       | Type   | Default       | Description                                          |
|--------------------------------|--------|---------------|------------------------------------------------------|
| `enable_monitoring`            | bool   | `true`        | Enable Azure Monitor and Log Analytics               |
| `log_retention_days`           | number | `30`          | Number of days to retain logs (30-365)               |
| `log_analytics_sku`            | string | `"PerGB2018"` | Log Analytics workspace SKU                          |
| `log_analytics_daily_quota_gb` | number | `-1`          | Daily data ingestion quota in GB (-1 = no limit)     |
| `app_insights_retention_days`  | number | `90`          | Application Insights data retention in days (30-730) |
| `enable_monitoring_dashboard`  | bool   | `true`        | Enable custom monitoring dashboard                   |

---

## Alerting Configuration

| Variable                       | Type         | Default                      | Description                                       |
|--------------------------------|--------------|------------------------------|---------------------------------------------------|
| `enable_infrastructure_alerts` | bool         | `true`                       | Enable infrastructure metric alerts               |
| `alert_email_addresses`        | list(string) | `["infrastructure@trl.com"]` | List of email addresses for alert notifications   |
| `cpu_alert_threshold`          | number       | `80`                         | CPU usage percentage threshold for alerts (1-100) |
| `memory_alert_threshold_bytes` | number       | `1073741824`                 | Available memory threshold in bytes for alerts    |
| `enable_security_alerts`       | bool         | `true`                       | Enable security-related alerts                    |

---

## Tagging Configuration

### Identity & Ownership Tags

| Variable           | Type   | Default                     | Description                                |
|--------------------|--------|-----------------------------|--------------------------------------------|
| `created_by`       | string | `"TRL Infrastructure Team"` | Person/team who created the resources      |
| `service_provider` | string | `"TRL Technology Services"` | Service provider responsible for resources |
| `owner_email`      | string | `"infrastructure@trl.com"`  | Email address of the resource owner        |
| `business_unit`    | string | `"Technology"`              | Business unit owning the resources         |

### Financial & Cost Management Tags

| Variable       | Type   | Default                    | Description                            |
|----------------|--------|----------------------------|----------------------------------------|
| `cost_center`  | string | `"IT-Infrastructure"`      | Cost center for billing and chargeback |
| `project_name` | string | `"Hub-Spoke-Architecture"` | Project name for the infrastructure    |

### Security & Compliance Tags

| Variable                  | Type         | Default                 | Description                                                            |
|---------------------------|--------------|-------------------------|------------------------------------------------------------------------|
| `data_classification`     | string       | `"Internal"`            | Data classification level (Public, Internal, Confidential, Restricted) |
| `compliance_requirements` | list(string) | `["ISO-27001", "SOC2"]` | Compliance frameworks applicable to resources                          |

### Operations & Recovery Tags

| Variable                 | Type   | Default                      | Description                                  |
|--------------------------|--------|------------------------------|----------------------------------------------|
| `backup_required`        | bool   | `true`                       | Whether resources require backup             |
| `disaster_recovery_tier` | string | `"Tier1"`                    | Disaster recovery tier (Tier1, Tier2, Tier3) |
| `maintenance_window`     | string | `"Saturday 02:00-06:00 UTC"` | Preferred maintenance window                 |

### Additional Custom Tags

| Variable          | Type        | Default   | Description                                      |
|-------------------|-------------|-----------|--------------------------------------------------|
| `additional_tags` | map(string) | See below | Additional custom tags to apply to all resources |

**Default additional_tags:**
```hcl
additional_tags = {
  Workspace       = "Hub"
  Purpose         = "Shared Services and Spokes"
  ManagedBy       = "Terraform"
  Repository      = "Azure.IAC.hubspoke"
  AutoShutdown    = "Enabled"
  CostOptimized   = "true"
}
```

---

## Output Variables

The hub workspace exposes comprehensive outputs for:

### Resource Groups
- Hub, Spoke, and Management resource group names and IDs

### Network Information
- VNet names, IDs, and address spaces for hub and spokes
- Subnet IDs for all network segments

### Security Components
- Firewall public and private IPs
- Bastion public IP
- Key Vault name, ID, and URI

### Virtual Machines
- VM IDs, names, and private IP addresses
- Admin username
- Connection information (RDP via Firewall and Bastion)

### Storage
- Main, diagnostics, premium, and data lake storage account details
- Blob endpoints

### Monitoring & Logging
- Log Analytics workspace details
- Workspace ID for integration

### Databases
- SQL Server and database information
- Cosmos DB endpoints

### Private DNS Zones
- All configured private DNS zones

### Deployment Summary
- Comprehensive summary of all enabled features and configurations

---

## Usage Example

Create a `terraform.tfvars` file:

```hcl
subscription_id = "your-subscription-id"
environment     = "prod"
location        = "West Europe"

# Network
enable_firewall        = true
enable_bastion         = true
enable_ddos_protection = false

# Spokes
spoke_count = 2

# Storage
storage_account_tier     = "Standard"
storage_replication_type = "GRS"
enable_premium_storage   = true
enable_data_lake_storage = true

# Monitoring
enable_monitoring       = true
log_retention_days      = 90
enable_monitoring_dashboard = true

# Alerting
alert_email_addresses = ["ops@company.com", "infrastructure@company.com"]
cpu_alert_threshold   = 85

# Tagging
created_by       = "Cloud Infrastructure Team"
service_provider = "Company IT Services"
cost_center      = "CC-12345"
business_unit    = "Engineering"
owner_email      = "cloudops@company.com"
```

---

October 29, 2025  
**Workspace:** Hub  
**Terraform Version:** >= 1.5.0

