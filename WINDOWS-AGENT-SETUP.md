# Windows Self-Hosted Agent Setup Guide

This guide helps you set up a Windows self-hosted Azure DevOps agent with all required dependencies for running the TRL Hub-Spoke infrastructure pipeline.



## 🔧 Required Software Installation

### 1. Install Azure CLI (Required)

**Option A: Using MSI Installer (Recommended)**

1. **Download Azure CLI**
   - Go to: https://aka.ms/installazurecliwindows
   - Or direct download: https://aka.ms/installazurecliwindowsx64
   
2. **Run the Installer**
   - Double-click the downloaded `.msi` file
   - Click **"Next"** → **"I accept"** → **"Install"**
   - Wait for installation (2-3 minutes)
   - Click **"Finish"**

3. **Verify Installation**
   ```powershell
   # Open new PowerShell window (restart required for PATH update)
   az --version
   
   # Expected output:
   # azure-cli                         2.x.x
   ```

**Option B: Using PowerShell Script**

```powershell
# Run PowerShell as Administrator
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindowsx64 -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
Remove-Item .\AzureCLI.msi

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Verify
az --version
```

**Option C: Using Chocolatey**

```powershell
# Install Chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Azure CLI
choco install azure-cli -y

# Verify
az --version
```

---

### 2. Install PowerShell 7+ (Recommended)

The pipeline uses `scriptType: 'pscore'` which requires PowerShell Core 7+.

**Check Current Version:**
```powershell
$PSVersionTable.PSVersion

# If less than 7.0, install PowerShell 7
```

**Install PowerShell 7:**

```powershell
# Option A: Using winget (Windows 11 / Windows 10 with App Installer)
winget install --id Microsoft.PowerShell --source winget

# Option B: Using MSI Installer
Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/PowerShell-7.5.4-win-x64.msi -OutFile PowerShell-7.msi
Start-Process msiexec.exe -Wait -ArgumentList '/package PowerShell-7.msi /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1'
Remove-Item PowerShell-7.msi

# Verify
pwsh --version
```

---

### 3. Install Terraform (Required)

**Option A: Using Chocolatey (Recommended)**

```powershell
choco install terraform -y --version=1.13.4

# Verify
terraform --version
```

**Option B: Manual Installation**

```powershell
# Download Terraform
$terraformVersion = "1.13.4"
$downloadUrl = "https://releases.hashicorp.com/terraform/$terraformVersion/terraform_${terraformVersion}_windows_amd64.zip"
Invoke-WebRequest -Uri $downloadUrl -OutFile terraform.zip

# Extract to C:\terraform
Expand-Archive -Path terraform.zip -DestinationPath C:\terraform -Force
Remove-Item terraform.zip

# Add to PATH permanently
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\terraform", [EnvironmentVariableTarget]::Machine)

# Refresh current session
$env:Path += ";C:\terraform"

# Verify
terraform --version
```

---

### 4. Install Git (Required for checkout)

**Using Chocolatey:**
```powershell
choco install git -y

# Verify
git --version
```

**Using Installer:**
- Download from: https://git-scm.com/download/win
- Run installer with default options

---

## 🔄 Restart Azure DevOps Agent

After installing all dependencies, restart the agent service:

```powershell
# Find your agent service name
Get-Service | Where-Object { $_.Name -like '*agent*' }

# Restart the service (replace with your service name)
Restart-Service -Name "vsts.agent.TRL-Agents.TRL-Agent-PAT-01"

# Or stop and start manually
Stop-Service -Name "vsts.agent.TRL-Agents.TRL-Agent-PAT-01"
Start-Service -Name "vsts.agent.TRL-Agents.TRL-Agent-PAT-01"

# Verify service is running
Get-Service -Name "vsts.agent.TRL-Agents.TRL-Agent-PAT-01"
```


## ✅ Verification Checklist

### Quick Diagnostic Script (Recommended)

For a comprehensive check of all dependencies, run the diagnostic script:

```powershell
# Run the comprehensive diagnostic script
cd C:\Users\mitre\Documents\Azure.IAC.hubspoke\scripts
.\agent-diagnostics.ps1

# This will check:
# - Azure CLI installation and version
# - PowerShell version and edition
# - Terraform installation
# - Git installation and PATH
# - System memory status
# - Azure DevOps agent service/process
# - Environment PATH entries
# - Agent capabilities
```

### Manual Verification

After installing everything, verify all components manually:

```powershell
Write-Host "=== Checking Required Dependencies ===" -ForegroundColor Green

# Check Azure CLI
Write-Host "`n1. Azure CLI:" -ForegroundColor Cyan
try {
    $azVersion = az --version | Select-Object -First 1
    Write-Host "   $azVersion" -ForegroundColor Green
} catch {
    Write-Host "   Azure CLI not installed" -ForegroundColor Red
}

# Check PowerShell version
Write-Host "`n2. PowerShell:" -ForegroundColor Cyan
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 7) {
    Write-Host "   PowerShell $psVersion" -ForegroundColor Green
} else {
    Write-Host "   PowerShell $psVersion (Upgrade to 7+ recommended)" -ForegroundColor Yellow
}

# Check Terraform
Write-Host "`n3. Terraform:" -ForegroundColor Cyan
try {
    $tfVersion = terraform --version | Select-Object -First 1
    Write-Host "   $tfVersion" -ForegroundColor Green
} catch {
    Write-Host "   Terraform not installed" -ForegroundColor Red
}

# Check Git
Write-Host "`n4. Git:" -ForegroundColor Cyan
try {
    $gitVersion = git --version 2>&1
    if ($LASTEXITCODE -eq 0 -or $gitVersion -like "*git version*") {
        Write-Host "   ✅ $gitVersion" -ForegroundColor Green
    } else {
        Write-Host "   Git not installed" -ForegroundColor Red
    }
} catch {
    Write-Host "   Git not installed" -ForegroundColor Red
}

# Check Memory
Write-Host "`n5. System Memory:" -ForegroundColor Cyan
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$percentUsed = [math]::Round((($os.TotalVisibleMemorySize-$os.FreePhysicalMemory)/$os.TotalVisibleMemorySize)*100,2)
$freeGB = [math]::Round($os.FreePhysicalMemory/1MB,2)
if ($percentUsed -lt 80) {
    Write-Host "   Memory Usage: $percentUsed% ($freeGB GB free)" -ForegroundColor Green
} elseif ($percentUsed -lt 90) {
    Write-Host "   Memory Usage: $percentUsed% ($freeGB GB free)" -ForegroundColor Yellow
} else {
    Write-Host "   Memory Usage: $percentUsed% ($freeGB GB free) - Too High!" -ForegroundColor Red
}

# Check Agent Service
Write-Host "`n6. Agent Service:" -ForegroundColor Cyan
$agentServices = Get-Service -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name -like '*vstsagent*' -or 
    $_.Name -like '*vsts.agent*' -or 
    $_.DisplayName -like '*Azure Pipelines Agent*' -or
    $_.DisplayName -like '*VSTS Agent*'
}

if ($agentServices) {
    foreach ($service in $agentServices) {
        if ($service.Status -eq 'Running') {
            Write-Host "   $($service.Name) - Running" -ForegroundColor Green
        } else {
            Write-Host "   $($service.Name) - $($service.Status)" -ForegroundColor Yellow
        }
    }
} else {
    # Alternative check: Look for running agent process
    $agentProcess = Get-Process -Name "Agent.Worker","Agent.Listener" -ErrorAction SilentlyContinue
    if ($agentProcess) {
        Write-Host "   Agent process is running (not installed as service)" -ForegroundColor Green
    } else {
        Write-Host "   No agent service or process found" -ForegroundColor Yellow
        Write-Host "      Run: Get-Service | Where-Object { `$_.DisplayName -like '*agent*' } to see all services" -ForegroundColor Gray
    }
}

Write-Host "`n=== Verification Complete ===" -ForegroundColor Green
```

---



## 📚 Additional Resources

- **Azure CLI Docs**: https://docs.microsoft.com/cli/azure/
- **PowerShell Docs**: https://docs.microsoft.com/powershell/
- **Terraform Docs**: https://www.terraform.io/docs
- **Agent Setup**: [PARALLELISM-ERROR-FIX.md](PARALLELISM-ERROR-FIX.md)
- **Pipeline Variables**: [PIPELINE-VARIABLES-GUIDE.md](PIPELINE-VARIABLES-GUIDE.md)

---

**Your pipeline should now run successfully!** 

