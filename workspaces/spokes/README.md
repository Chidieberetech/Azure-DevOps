# Spoke Workspaces Overview

## What are Spoke Workspaces?

**Spoke Workspaces** are environment-specific workspaces that host **application workloads** in the hub-spoke architecture. Each spoke represents a separate environment (dev, int, prod) and is peered to the central Hub workspace for connectivity.

---

## Available Spoke Workspaces

| Workspace       | Path      | Purpose                     | Environment |
|-----------------|-----------|-----------------------------|-------------|
| **Development** | `./dev/`  | Development and testing     | `dev`       |
| **Integration** | `./int/`  | Integration testing and UAT | `int`       |
| **Production**  | `./prod/` | Production workloads        | `prod`      |

---

## Architecture Position

```
┌─────────────────────────────┐
│   MANAGEMENT WORKSPACE      │
│   (Monitoring & Governance) │
└─────────────┬───────────────┘
              │ Monitors
              ▼
    ┌─────────────────────┐
    │   HUB WORKSPACE     │
    │   (Networking)      │
    └────┬────────┬───────┘
         │        │
    ┌────┴───┐ ┌─┴────────┐ ┌──────────┐
    │ SPOKE  │ │ SPOKE    │ │ SPOKE    │
    │ DEV    │ │ INT      │ │ PROD     │
    │        │ │          │ │          │
    └────────┘ └──────────┘ └──────────┘
```

---

## What Do Spoke Workspaces Deploy?

### Core Components

#### 1. **Networking**
- Virtual Network (VNet) - Peered to Hub
- Subnets (workload, VM, database, private endpoint)
- Network Security Groups (NSGs)
- VNet peering to Hub

#### 2. **Compute**
- Virtual Machines (Windows/Linux)
- Auto-shutdown schedules (for cost optimization)
- VM monitoring and diagnostics

#### 3. **Databases**
- SQL Database (optional)
- Cosmos DB (optional)
- Database monitoring and alerts

#### 4. **Storage**
- Storage accounts
- Blob storage
- File shares
- Private endpoints for storage

#### 5. **Security**
- Private endpoints for services
- Integration with hub's private DNS
- Connection to centralized Key Vault

#### 6. **Monitoring**
- Integration with Management workspace Log Analytics
- Application Insights
- Custom dashboards and alerts

---

## 🚫 What Spoke Workspaces Do NOT Deploy

- ❌ **Azure Firewall** (managed by Hub)
- ❌ **Azure Bastion** (managed by Hub)
- ❌ **Private DNS Zones** (managed by Hub)
- ❌ **Additional Spokes** (not a hub)

---

## Spoke Workspace Differences

| Feature               | Dev Spoke             | Int Spoke         | Prod Spoke                |
|-----------------------|-----------------------|-------------------|---------------------------|
| **Environment**       | `dev`                 | `int`             | `prod`                    |
| **Purpose**           | Development & Testing | Integration & UAT | Production                |
| **VM Auto-Shutdown**  | ✅ Enabled (default)   | ✅ Enabled         | ⚠️ Optional               |
| **VM Size**           | Smaller (B-series)    | Medium            | Larger (production-grade) |
| **High Availability** | ❌ Single instance     | ⚠️ Optional       | ✅ Recommended             |
| **Backup**            | ⚠️ Optional           | ✅ Recommended     | ✅✅ Required               |
| **Log Retention**     | 30 days               | 60 days           | 90+ days                  |
| **Cost Optimization** | ✅✅ Aggressive         | ✅ Moderate        | ⚠️ Performance focused    |
| **Database SKU**      | Basic/S0              | S1/S2             | Premium options           |

---

##  Integration with Other Workspaces

### Spoke → Hub Workspace
Each spoke:
- Peers its VNet to the Hub VNet
- Uses Hub's Azure Firewall for internet egress
- Connects to VMs via Hub's Azure Bastion
- Uses Hub's Private DNS zones

### Spoke → Management Workspace
Each spoke:
- Sends logs to Management's Log Analytics
- Stores diagnostics in Management's storage
- Uses Management's Key Vault for secrets
- Reports metrics to centralized dashboards

---

## Quick Start

### 1. Choose Your Environment

```bash
# For Development
cd workspaces/spokes/dev

# For Integration
cd workspaces/spokes/int

# For Production
cd workspaces/spokes/prod
```

### 2. Configure Variables

Create a `terraform.tfvars` file:

```hcl
subscription_id = "your-subscription-id"
environment     = "dev"  # or "int" or "prod"

# Enable features as needed
enable_sql_database = true
enable_cosmos_db    = false

# VM configuration
vm_size         = "Standard_B2s"
admin_username  = "azureadmin"

# Tagging
created_by       = "Your Team Name"
service_provider = "Your Company"
cost_center      = "CC-12345"
owner_email      = "team@company.com"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

---

## Common Configuration Patterns

### Pattern 1: Development Environment
```hcl
environment             = "dev"
vm_size                 = "Standard_B1s"
enable_vm_auto_shutdown = true
vm_shutdown_time        = "1900"
enable_sql_database     = true
sql_database_sku        = "Basic"
storage_replication_type = "LRS"
log_retention_days      = 30
```

### Pattern 2: Production Environment
```hcl
environment              = "prod"
vm_size                  = "Standard_D2s_v3"
enable_vm_auto_shutdown  = false
enable_sql_database      = true
sql_database_sku         = "S2"
storage_replication_type = "GRS"
log_retention_days       = 90
enable_backup            = true
```

---

## Remote State Integration

### Connect to Hub Workspace

```hcl
data "terraform_remote_state" "hub" {
  backend = "azurerm"
  config = {
    resource_group_name  = "trl-hubspoke-tfstate-rg"
    storage_account_name = "trlhubspoketfstate"
    container_name       = "tfstate"
    key                  = "hub.terraform.tfstate"
  }
}

# Use hub VNet for peering
hub_vnet_id = data.terraform_remote_state.hub.outputs.hub_vnet_id
```

### Connect to Management Workspace

```hcl
data "terraform_remote_state" "management" {
  backend = "azurerm"
  config = {
    resource_group_name  = "trl-hubspoke-tfstate-rg"
    storage_account_name = "trlhubspoketfstate"
    container_name       = "tfstate"
    key                  = "management.terraform.tfstate"
  }
}

# Use centralized Log Analytics
log_analytics_workspace_id = data.terraform_remote_state.management.outputs.log_analytics_workspace_id
```

---

## Best Practices

### Development Spoke
1. Enable auto-shutdown to save costs
2. Use smaller VM sizes (B-series)
3. Use LRS storage replication
4. Keep log retention minimal (30 days)
5. Enable aggressive cost optimization

### Integration Spoke
1. Mirror production configuration (but smaller)
2. Use moderate VM sizes
3. Enable backup for critical resources
4. Test disaster recovery procedures
5. Use GRS for important data

### Production Spoke
1. Use production-grade VM sizes
2. Enable high availability zones
3. Implement backup and disaster recovery
4. Use GRS or RAGRS storage
5. Extended log retention (90+ days)
6. Enable all monitoring and alerting
7. Disable auto-shutdown

---

## 🏷Tagging Strategy

All spoke workspaces should include:

```hcl
additional_tags = {
  Workspace             = "Spoke-Dev"  # or Int/Prod
  Environment           = "dev"        # or int/prod
  "Created By"          = "Team Name"
  "Service Provider"    = "Company IT"
  "Cost Center"         = "CC-12345"
  "Business Unit"       = "Engineering"
  "Owner Email"         = "team@company.com"
  "Data Classification" = "Internal"
  "Backup Required"     = "Yes"
  "DR Tier"             = "Tier2"
  ManagedBy             = "Terraform"
  Repository            = "Azure.IAC.hubspoke"
}
```

---

##  Troubleshooting

### Issue: Cannot connect to VMs
**Solution:** Use Azure Bastion from the Hub workspace:
1. Navigate to VM in Azure Portal
2. Click "Connect" → "Bastion"
3. Enter credentials from Key Vault

### Issue: No internet connectivity
**Solution:** Check Hub Firewall rules:
- Ensure DNAT rules are configured
- Verify network rules allow traffic
- Check spoke subnet route table

### Issue: Private endpoints not resolving
**Solution:** Verify Hub Private DNS integration:
- Check VNet link to Hub's private DNS zones
- Verify private endpoint configuration
- Test DNS resolution from VM

---

## Related Documentation

- [Hub Workspace Guide](../hub/VARIABLES-SUMMARY.md)
- [Management Workspace Guide](../management/README.md)
- [Workspace Comparison](../../WORKSPACE-COMPARISON.md)
- [Azure Virtual Networks](https://docs.microsoft.com/azure/virtual-network/)
- [VNet Peering](https://docs.microsoft.com/azure/virtual-network/virtual-network-peering-overview)

---

## Workspace Structure

```
spokes/
├── README.md           # This file
├── dev/
│   └── main.tf        # Development environment
├── int/
│   └── main.tf        # Integration environment
└── prod/
    └── main.tf        # Production environment
```

---

**Last Updated:** October 29, 2025  
**Workspace Type:** Spoke Environments  
**Terraform Version:** >= 1.5.0

