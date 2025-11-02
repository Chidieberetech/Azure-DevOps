# Azure DevOps Parallelism Error - Solutions Guide

##  Error Message

```
##[error]No hosted parallelism has been purchased or granted.
To request a free parallelism grant, please fill out the following form
https://aka.ms/azpipelines-parallelism-request
```

---

##  What This Means

Azure DevOps requires **parallelism** to run pipelines on **Microsoft-hosted agents** (ubuntu-latest, windows-latest, etc.). 

For new organizations or free accounts:
-  Microsoft-hosted parallelism is NOT automatically granted
-  You need to either request free access OR use self-hosted agents

---

##  Solution Options

### **Option 1: Request Free Parallelism (Recommended for Quick Start)** 

#### **Steps:**

1. **Fill Out the Form:**
   - Go to: https://aka.ms/azpipelines-parallelism-request
   - Fill in your details:
     - Organization name
     - Azure DevOps organization URL
     - Reason for request (select appropriate option)
   - Submit the form

2. **Wait for Approval:**
   - ⏱️ Usually takes 2-3 business days
   - You'll receive email confirmation
   - Once approved, you get **1 free Microsoft-hosted parallel job**

3. **Run Your Pipeline:**
   - After approval, your pipeline will work with `vmImage: 'ubuntu-latest'`

**Pros:**
-  No infrastructure setup required
-  Microsoft manages the agents
-  Always up-to-date
-  Free for public projects and 1 job for private

**Cons:**
- ️ Requires approval (2-3 days wait)
- ️ Limited to 1 parallel job (free tier)
- ️ 1800 minutes/month limit (free tier)

---

### **Option 2: Use Self-Hosted Agent (Immediate Solution)** 

Use your own machine/VM as a build agent. **Works immediately!**

#### **Quick Setup Steps:**

##### **Step 1: Create Agent Pool**

1. Go to: **Organization Settings** → **Agent pools**
2. Click **Add pool**
3. Settings:
   - Pool type: **Self-hosted**
   - Name: `TRL-Agents`
   - Grant access to all pipelines:  Check
4. Click **Create**

##### **Step 2: Install Agent on Your Machine**

To find the list of agent in WIndows
```powershell

Get-Service | Where-Object { $_.Name -like '*agent*' -or $_.DisplayName -like '*agent*' }
```

##### **Step 2: Download and Install Agent**

**On Windows:**


Ther version might be updated, at the momenet of writing this documenatation the latest is v4.261.0. Check [here](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/v2-windows?view=azure-devops) for the latest version.
It's recommended to use the latest stable version.

```powershell
# Create agent directory
mkdir C:\agents
cd C:\agents

# Download agent
Invoke-WebRequest -Uri https://download.agent.dev.azure.com/agent/4.261.0/vsts-agent-win-x64-4.261.0.zip -OutFile agent.zip

# Extract
Expand-Archive -Path agent.zip -DestinationPath .

# Configure agent
.\config.cmd

# When prompted:
# - Server URL: https://dev.azure.com/your-organization
# Enter a valid authentication type: PAT (Press Enter for PAT)
# Provide PAT token: (create one in Azure DevOps)
# - PAT token: (create one in Azure DevOps) 
# - Agent pool: TRL-Agents (this name must match the pool created earlier)
# - Agent name: TRL-Agent-PAT-01 (this can be any name you choose)
# - Work folder: _work
```

**On Linux/Ubuntu:**

```bash
# Create agent directory
mkdir ~/agents && cd ~/agents

# Download agent
wget https://download.agent.dev.azure.com/agent/4.261.0/vsts-agent-linux-x64-4.261.0.tar.gz

# Extract
tar zxvf vsts-agent-linux-x64-4.261.0.tar.gz

# Configure agent
./config.sh

# When prompted:
# - Server URL: https://dev.azure.com/organization (it can be https://dev.azure.com/waterLLC for example)
# - PAT token: (create one in Azure DevOps)
# - Agent pool: TRL-Agents
# - Agent name: TRL-Agents-01
# - Work folder: _work (folder to use for builds)
```

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

##### **Step 3: Create Personal Access Token (PAT)**

1. Azure DevOps → User Settings (top right) → **Personal Access Tokens**
2. Click **+ New Token**
3. Settings:
   - Name: `TRL-Agent-PAT`
   - Organization: Select your organization
   - Scopes: **Agent Pools (Read & manage)**
   - Expiration: 90 days (or custom)
4. Click **Create**
5. **Copy the token** (you won't see it again!)
6. Use this token when configuring the agent

##### **Step 4: Update Pipeline to Use Self-Hosted Pool**

Edit `pipelines/azure-pipelines-main.yml`:

```yaml
# BEFORE (Microsoft-hosted):
pool:
  vmImage: 'ubuntu-latest'

# AFTER (Self-hosted):
pool:
  name: 'TRL-Agents'
```

****
## Stop and Disable a Self\-Hosted Agent

Use these steps to stop the local agent process/service, disable it from starting, or take it offline in the Azure DevOps UI.

### Windows (PowerShell, elevated)
- Find agent service and stop/disable it.
```powershell
# Find agent service
Get-Service | Where-Object { $_.Name -like '*agent*' -or $_.DisplayName -like '*agent*' }

# Stop and disable the service (replace service name)
Stop-Service -Name 'vsts.agent.TRL-Agents.TRL-Agent-PAT-01'
Set-Service -Name 'vsts.agent.TRL-Agents.TRL-Agent-PAT-01' -StartupType Disabled
```
Optional: unregister and remove agent config (run in agent folder).

```powershell
cd `C:\agents\TRL-Agents`
.\config.cmd remove --unattended --auth PAT --token <PAT>
```

Linux (systemd or svc script)
Stop and disable systemd service (replace service name) or use the agent svc scripts.

```bash
# Stop and disable systemd service
sudo systemctl stop vsts.agent.TRL-Agents.TRL-Agent-01.service
sudo systemctl disable vsts.agent.TRL-Agents.TRL-Agent-01.service

#or using agent svc scripts (in agent folder)
cd ~/agents/TRL-Agents
sudo ./svc.sh stop
sudo ./svc.sh uninstall 
```
Optional: unregister and remove agent config (run in agent folder). 
```bash
cd ~/agents/TRL-Agents
./config.sh remove --unattended --auth PAT --token <PAT>
```

**Pros:**
-  Works immediately (no approval needed)
-  Unlimited build minutes
-  Can install custom software/tools
-  Faster builds (no queue time)
-  Can access on-premises resources

**Cons:**
- ️ You manage the infrastructure
- ️ Need to keep agent updated
- ️ Requires a machine to run 24/7 (for on-demand builds)

---

### **Option 3: Use Azure DevOps Free Tier (Public Projects)**

If your project is **open source/public**:

1. Make your repository **public**
2. Azure DevOps grants **10 free parallel jobs** for public projects
3. Unlimited build minutes

**Steps:**
1. Go to Project Settings → Overview
2. Change visibility to **Public**
3. Your pipeline will work immediately

**Pros:**
-  10 free parallel jobs
-  Unlimited minutes
-  No approval needed

**Cons:**
- ️ Code must be public
- ️ Not suitable for private/enterprise projects

---

### **Option 4: Purchase Parallelism**

For enterprise/production use:

1. Go to: **Organization Settings** → **Billing**
2. Click **Set up billing**
3. Purchase parallel jobs:
   - Microsoft-hosted: $40/month per parallel job
   - Self-hosted: $15/month per parallel job

---

##  Recommended Approach for Project

### **For Immediate Testing: Self-Hosted Agent** 

**Why:**
-  Works today (no waiting)
-  Free
-  Good for testing the pipeline

**Quick Start:**
1. Install agent on your local machine
2. Update pipeline pool configuration
3. Run pipeline immediately

---

### **For Long-Term Production: Request Free Parallelism + Self-Hosted** 

**Why:**
-  Best of both worlds
-  Microsoft-hosted for standard builds
-  Self-hosted for special requirements

**Plan:**
1. Set up self-hosted agent now (for immediate use)
2. Request free parallelism (for future flexibility)
3. Use both as needed

---

##  Updated Pipeline Configuration

I've created two versions of the pool configuration for you:

### **Version A: Microsoft-Hosted (After Approval)**

```yaml
#================================================
# POOL CONFIGURATION - Microsoft-Hosted
#================================================
pool:
  vmImage: 'ubuntu-latest'
  # Requires free parallelism approval
  # Request at: https://aka.ms/azpipelines-parallelism-request
```

### **Version B: Self-Hosted (Works Immediately)**

```yaml
#================================================
# POOL CONFIGURATION - Self-Hosted
#================================================
pool:
  name: 'TRL-Agents'
  # Self-hosted agent pool (no approval needed)
  # Setup: Organization Settings → Agent pools → Add pool
```

### **Version C: Hybrid (Recommended)**

```yaml
#================================================
# POOL CONFIGURATION - Hybrid
#================================================
pool:
  # Option 1: Use self-hosted agents (immediate)
  name: 'TRL-Agents'
  
  # Option 2: Use Microsoft-hosted (after approval)
  # Uncomment after getting parallelism approval:
  # vmImage: 'ubuntu-latest'
```

---

##  Quick Fix - Update Your Pipeline Now

I'll update your main pipeline to use a self-hosted agent pool by default.

**File:** `pipelines/azure-pipelines-main.yml`

**Change:**
```yaml
pool:
  name: 'TRL-Agents'  # Self-hosted pool
  # vmImage: 'ubuntu-latest'  # Uncomment after parallelism approval
```

This allows you to:
1. Set up self-hosted agent now → pipeline works immediately
2. Request parallelism → switch to Microsoft-hosted later

---

##  Checklist

### **Immediate Solution (Self-Hosted):**
- [ ] Create agent pool `TRL-Agents` in Azure DevOps
- [ ] Install agent on a machine (Windows/Linux)
- [ ] Configure agent with PAT token
- [ ] Start agent service
- [ ] Update pipeline pool configuration
- [ ] Run pipeline 

### **Long-Term Solution (Free Parallelism):**
- [ ] Fill out form: https://aka.ms/azpipelines-parallelism-request
- [ ] Wait for approval (2-3 business days)
- [ ] Receive confirmation email
- [ ] Update pipeline to use `vmImage: 'ubuntu-latest'`
- [ ] Run pipeline with Microsoft-hosted agents 

---

## 🔧 Troubleshooting

### **Agent Not Showing in Pool**
```bash
# Check agent status
./run.sh  # Linux
./run.cmd # Windows

# Verify agent configuration
cat .agent  # Linux
type .agent # Windows
```

### **Agent Authentication Failed**
- Verify PAT token has not expired
- Ensure PAT has "Agent Pools (Read & manage)" scope
- Create new PAT if needed

### **Pipeline Still Uses Microsoft-Hosted**
- Ensure all `pool:` sections in pipeline use `name: 'TRL-Agents'`
- Check templates also use self-hosted pool
- Verify pool name matches exactly

---

## Best Practices

### **Self-Hosted Agents:**
1. **Use dedicated VM/machine** - Don't use development machine
2. **Install required tools** - Terraform, Azure CLI, etc.
3. **Keep agent updated** - Check for updates monthly
4. **Run as service** - Automatic start on reboot
5. **Monitor disk space** - Clean up work folder periodically

### **Microsoft-Hosted Agents:**
1. **Cache dependencies** - Use pipeline caching
2. **Minimize build time** - Stay within 1800 min/month
3. **Use for standard builds** - Let Microsoft manage updates
4. **Self-hosted for special cases** - Custom tools, on-prem access

---

##  Cost Comparison

| Option                    | Setup Time | Monthly Cost | Build Minutes | Parallel Jobs |
|---------------------------|------------|--------------|---------------|---------------|
| **Free Parallelism**      | 2-3 days   | $0           | 1800          | 1             |
| **Self-Hosted**           | 30 mins    | $0           | Unlimited     | Unlimited     |
| **Public Project**        | Immediate  | $0           | Unlimited     | 10            |
| **Paid Microsoft-Hosted** | Immediate  | $40          | Unlimited     | 1 per $40     |
| **Paid Self-Hosted**      | 30 mins    | $15          | Unlimited     | 1 per $15     |

---

## Recommended Action

**For your TRL Hub-Spoke project:**

1. **Today:** Set up self-hosted agent (30 minutes)
2. **Today:** Request free parallelism (fill form)
3. **This Week:** Run pipeline on self-hosted agent
4. **Next Week:** Switch to Microsoft-hosted after approval

This gives you:
- Immediate ability to run pipelines
-  Future flexibility with Microsoft-hosted
-  Zero cost
-  Best of both worlds

---

**Status:**  **Solutions Available - Choose Your Path!**

**Quick Start:** Self-hosted agent (works today)  
**Recommended:** Self-hosted now + Request parallelism for later

---

**Last Updated:** October 30, 2025  
**Next Step:** Choose option and follow setup steps above

