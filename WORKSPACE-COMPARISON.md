# Workspace Comparison Guide

## Quick Reference: Hub vs Management vs Spoke Workspaces

| Feature                   | Hub Workspace                    | Management Workspace    | Spoke Workspaces      |
|---------------------------|----------------------------------|-------------------------|-----------------------|
| **Primary Purpose**       | Shared networking & connectivity | Monitoring & governance | Application workloads |
| **Network Components**    | ✅ Yes (Firewall, Bastion, VNets) | ❌ No                    | ✅ Yes (VNets only)    |
| **Deploys Spokes**        | ✅ Yes (0-3)                      | ❌ No (always 0)         | N/A                   |
| **Monitoring**            | ✅ Optional                       | ✅✅ **Primary**          | ✅ Sends to Management |
| **Key Vault**             | ✅ Optional                       | ✅✅ **Centralized**      | ✅ Optional            |
| **Virtual Machines**      | ✅ In spokes                      | ❌ No                    | ✅✅ **Primary**        |
| **Databases**             | ✅ Optional                       | ❌ No                    | ✅✅ **Primary**        |
| **Storage**               | ✅ Yes                            | ✅✅ **Diagnostics**      | ✅ Yes                 |
| **Azure Firewall**        | ✅✅ **Central hub**               | ❌ No                    | ❌ No                  |
| **Azure Bastion**         | ✅✅ **Central**                   | ❌ No                    | ❌ No                  |
| **Private DNS**           | ✅✅ **Central**                   | ❌ No                    | ❌ No                  |
| **Log Analytics**         | ✅ Optional                       | ✅✅ **Centralized**      | ❌ Uses Management     |
| **Cost Alerts**           | ✅ Optional                       | ✅✅ **Primary**          | ✅ Optional            |
| **Default Environment**   | prod                             | prod                    | dev/int/prod          |
| **Typical Log Retention** | 30 days                          | 90+ days                | 30 days               |
| **Storage Replication**   | LRS                              | GRS (recommended)       | LRS                   |

---

## Deployment Order

```
1. Management Workspace  (monitoring infrastructure)
         ↓
2. Hub Workspace        (networking & shared services)
         ↓
3. Spoke Workspaces     (application workloads)
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│              🎛️ MANAGEMENT WORKSPACE                    │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Log Analytics  │  Key Vault  │  Cost Management │   │
│  │  Alerts         │  Dashboards │  Compliance      │   │
│  └──────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────┘
                        │ (Monitoring & Governance)
                        ▼
        ┌───────────────────────────────────────┐
        │      🏢 HUB WORKSPACE                 │
        │  ┌────────────────────────────────┐   │
        │  │ Firewall  │ Bastion │ DNS     │   │
        │  │ Shared Services                │   │
        │  └────────────────────────────────┘   │
        └──────────┬──────────────┬─────────────┘
                   │              │
        ┌──────────┴──────┐  ┌───┴──────────┐
        │ 🔧 SPOKE 1      │  │ 🔧 SPOKE 2   │
        │  (Dev/Test)     │  │  (Production)│
        │  VMs, DBs, Apps │  │  VMs, DBs    │
        └─────────────────┘  └──────────────┘
```

---

## When to Use Each Workspace

### Use Management Workspace For:
 Centralized logging and monitoring  
 Security and compliance tracking  
 Cost management and budgets  
 Shared secrets management  
 Operational dashboards  
 Cross-workspace governance  

### Use Hub Workspace For:
 Central networking infrastructure  
 Azure Firewall (traffic filtering)  
 Azure Bastion (secure VM access)  
 Private DNS zones  
 Shared services (if needed)  
 Creating and managing spoke networks  

### Use Spoke Workspaces For:
 Application workloads  
 Virtual machines  
 Databases  
 Application services  
 Environment isolation (dev/int/prod)  
 Workload-specific resources  

---

## Variable Highlights

### Management Workspace Unique Variables
```hcl
enable_cost_management_alerts = true
monthly_budget_amount        = 5000
log_retention_days           = 90    # Longer for compliance
storage_replication_type     = "GRS" # Geo-redundant
```

### Hub Workspace Unique Variables
```hcl
enable_firewall        = true
enable_bastion         = true
enable_private_dns     = true
spoke_count            = 2
enable_ddos_protection = false
```

### Spoke Workspace Unique Variables
```hcl
environment              = "dev"  # or "int" or "prod"
enable_sql_database      = true
enable_cosmos_db         = true
vm_size                  = "Standard_B1s"
enable_vm_auto_shutdown  = true
```

---

## Tagging Strategy

### All Workspaces Share:
- "Created By"
- "Service Provider"
- "Cost Center"
- "Business Unit"
- "Project Name"
- "Owner Email"
- "Data Classification"
- "Compliance Requirements"
- "Backup Required"
- "Disaster Recovery Tier"
- "Maintenance Window"

### Workspace-Specific Tags:
| Tag           | Hub               | Management                | Spoke                   |
|---------------|-------------------|---------------------------|-------------------------|
| Workspace     | "Hub"             | "Management"              | "Spoke-Dev/Int/Prod"    |
| Purpose       | "Shared Services" | "Monitoring & Governance" | "Application Workloads" |
| WorkspaceType | -                 | "Management"              | -                       |

---

## Resource Naming Convention

```
Format: {org}-{workspace}-{resource}-{environment}-{region}

Examples:
- trl-hub-vnet-prod-we          (Hub VNet)
- trl-mgmt-laws-prod-we         (Management Log Analytics)
- trl-spoke-vm-dev-we           (Spoke VM in Dev)
- trl-hub-fw-prod-we            (Hub Firewall)
- trl-mgmt-kv-prod-we           (Management Key Vault)
```

---

## Common Integration Patterns

### Pattern 1: Spokes → Management Monitoring
```hcl
# In spoke workspace
data "terraform_remote_state" "management" {
  backend = "azurerm"
  config = {
    key = "management.terraform.tfstate"
  }
}

# Use management Log Analytics
log_analytics_workspace_id = data.terraform_remote_state.management.outputs.log_analytics_workspace_id
```

### Pattern 2: Spokes → Hub Networking
```hcl
# In spoke workspace
data "terraform_remote_state" "hub" {
  backend = "azurerm"
  config = {
    key = "hub.terraform.tfstate"
  }
}

# Peer to hub VNet
remote_virtual_network_id = data.terraform_remote_state.hub.outputs.hub_vnet_id
```

### Pattern 3: All → Management Key Vault
```hcl
# Reference centralized secrets
data "azurerm_key_vault_secret" "db_password" {
  name         = "database-password"
  key_vault_id = data.terraform_remote_state.management.outputs.key_vault_id
}
```

---

October 29, 2025  
**Purpose:** Workspace comparison and selection guide

