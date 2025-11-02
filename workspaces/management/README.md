# Management Workspace Overview

## What is the Management Workspace?

The **Management Workspace** is a **dedicated environment for centralized monitoring, governance, and operational management** of your entire Azure infrastructure. It serves as the **"Control Tower"** for  hub-spoke architecture.

### Key Differences from Other Workspaces

| Aspect                 | Hub Workspace                        | Spoke Workspaces      | Management Workspace                 |
|------------------------|--------------------------------------|-----------------------|--------------------------------------|
| **Purpose**            | Shared networking & services         | Application workloads | Monitoring & governance              |
| **Network Components** | Firewall, Bastion, VNets             | VNets (peered to hub) | ❌ None (uses hub networking)         |
| **Spokes**             | Can deploy 0-3 spokes                | N/A                   | ❌ Always 0                           |
| **Primary Focus**      | Connectivity & security              | Workload hosting      | Operations & compliance              |
| **Key Resources**      | Azure Firewall, Bastion, Private DNS | VMs, databases, apps  | Log Analytics, Key Vault, monitoring |

---

## What Does the Management Workspace Deploy?

### Core Components

#### 1. **Monitoring & Logging**
- **Log Analytics Workspace**: Centralized log collection and analysis
- **Application Insights**: Application performance monitoring
- **Monitoring Dashboards**: Custom visualization of metrics and logs
- **Workbooks**: Interactive reporting and analysis

#### 2. **Security & Compliance**
- **Azure Key Vault**: Centralized secrets, keys, and certificate management
- **Security Alerts**: Security Center integration
- **Compliance Monitoring**: Policy compliance tracking

#### 3. **Operational Management**
- **Alerting Infrastructure**: Metric and log-based alerts
- **Cost Management**: Budget tracking and alerts
- **Diagnostics Storage**: Long-term storage for diagnostics data

#### 4. **Resource Governance**
- **Resource Groups**: Organized management structure
- **Tags**: Comprehensive tagging for governance
- **RBAC**: Role-based access control

---

## 🚫 What the Management Workspace Does NOT Deploy

- ❌ **Azure Firewall** (managed by Hub workspace)
- ❌ **Azure Bastion** (managed by Hub workspace)
- ❌ **Virtual Networks** (managed by Hub workspace)
- ❌ **Private DNS Zones** (managed by Hub workspace)
- ❌ **Spoke Networks** (always 0 spokes)
- ❌ **Virtual Machines** (deployed in Spoke workspaces)

---

## 🏗️ Architecture Position

```
┌─────────────────────────────────────────────────────────────┐
│                   MANAGEMENT WORKSPACE                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │   Log Analytics  │   Key Vault  │  Monitoring        │   │
│  │   Alerts         │   Cost Mgmt  │  Compliance        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                             │
                             │ (Monitoring & Governance)
                             ▼
        ┌────────────────────────────────────────┐
        │             HUB WORKSPACE              │
        │   Firewall  │   Bastion  │   DNS       │
        └────────────────────────────────────────┘
                │                    │
        ┌───────┴──────┐    ┌────────┴──────┐
        │   SPOKE 1    │    │   SPOKE 2     │
        │  (Dev/Test)  │    │  (Production) │
        └──────────────┘    └───────────────┘
```

---

## Configuration Variables

### Core Configuration
- `subscription_id` - Azure subscription ID (required)
- `environment` - Environment name (default: "prod")
- `location` - Azure region (default: "West Europe")

### Network Configuration (All Disabled)
- `enable_firewall` = `false` (always)
- `enable_bastion` = `false` (always)
- `enable_private_dns` = `false` (always)
- `spoke_count` = `0` (always)

### Monitoring & Governance
- `enable_monitoring` - Enable monitoring (default: `true`)
- `log_retention_days` - Log retention (default: 90 days)
- `log_analytics_sku` - SKU for Log Analytics (default: "PerGB2018")
- `app_insights_retention_days` - App Insights retention (default: 90 days)
- `enable_monitoring_dashboard` - Custom dashboards (default: `true`)

### Alerting Configuration
- `enable_infrastructure_alerts` - Infrastructure alerts (default: `true`)
- `alert_email_addresses` - Email list for alerts
- `enable_security_alerts` - Security alerts (default: `true`)
- `enable_cost_management_alerts` - Cost alerts (default: `true`)
- `monthly_budget_amount` - Budget threshold (default: $5000)

### Security
- `enable_key_vault` - Enable Key Vault (default: `true`)
- `enable_key_vault_soft_delete` - Soft delete (default: `true`)

### Storage
- `storage_account_tier` - Storage tier (default: "Standard")
- `storage_replication_type` - Replication (default: "GRS")

### Tagging
Comprehensive tagging including:
- Identity & Ownership: `created_by`, `service_provider`, `owner_email`, `business_unit`
- Financial: `cost_center`, `project_name`
- Security: `data_classification`, `compliance_requirements`
- Operations: `backup_required`, `disaster_recovery_tier`, `maintenance_window`

---



---

## Integration with Other Workspaces

### Hub Workspace → Management Workspace
The Hub workspace sends:
- Network flow logs → Log Analytics
- Firewall logs → Log Analytics
- Bastion connection logs → Log Analytics
- NSG diagnostics → Storage Account

### Spoke Workspaces → Management Workspace
Each Spoke workspace sends:
- VM diagnostics → Log Analytics
- Application logs → Application Insights
- Performance metrics → Log Analytics
- Security events → Security Center

---

## Use Cases

### 1. **Centralized Monitoring**
Monitor all workspaces from a single Log Analytics workspace:
```hcl
# In spoke workspaces, reference management workspace Log Analytics
data "terraform_remote_state" "management" {
  backend = "azurerm"
  config = {
    key = "management.terraform.tfstate"
  }
}

log_analytics_workspace_id = data.terraform_remote_state.management.outputs.log_analytics_workspace_id
```

### 2. **Cost Management**
Track spending across all workspaces with centralized cost alerts and budgets.

### 3. **Security & Compliance**
- Centralized Key Vault for secrets shared across workspaces
- Security Center for unified security posture
- Compliance dashboards and reports

### 4. **Operational Excellence**
- Unified alerting for infrastructure and applications
- Custom dashboards showing health of all workspaces
- Automated remediation workflows

---

## Deployment

```bash
cd workspaces/management
terraform init
terraform plan
terraform apply
```

---

## Best Practices

1. **Deploy First**: Deploy the management workspace before hub and spokes to have monitoring ready
2. **Long Retention**: Use longer log retention (90+ days) for compliance
3. **Geo-Redundant Storage**: Use GRS for diagnostics storage for disaster recovery
4. **Cost Controls**: Set up budget alerts to prevent unexpected costs
5. **Access Control**: Limit access to management workspace to operations team only
6. **Backup Key Vault**: Enable soft delete and purge protection for Key Vault
7. **Monitor the Monitor**: Set up alerts for Log Analytics workspace health

---

## Related Documentation

- [Hub Workspace Guide](../hub/VARIABLES-SUMMARY.md)
- [Spoke Workspace Guide](../spokes/README.md)
- [Azure Log Analytics Documentation](https://docs.microsoft.com/azure/azure-monitor/logs/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)

---

**Last Updated:** October 29, 2025  
**Workspace Type:** Management  
**Terraform Version:** >= 1.5.0

