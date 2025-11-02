param(
    [string]$Version = "1.13.4",
    [string]$InstallRoot = "C:\Terraform",
    [switch]$MachinePath
)

# Step 0: helper
function Write-ErrAndExit($msg) {
    Write-Error $msg
    exit 1
}

# Compose download URL (windows amd64)
$zipUrl = "https://releases.hashicorp.com/terraform/$Version/terraform_${Version}_windows_amd64.zip"

# Check whether the release exists
try {
    Invoke-WebRequest -Uri $zipUrl -Method Head -UseBasicParsing -ErrorAction Stop | Out-Null
} catch {
    Write-ErrAndExit "Terraform version '$Version' not found at $zipUrl. Check the version string (examples: 1.3.4 or 0.13.4)."
}

# Download zip
$tempZip = Join-Path $env:TEMP "terraform_$Version.zip"
Write-Output "Downloading $zipUrl to $tempZip ..."
Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing -ErrorAction Stop

# Extract
$dest = Join-Path $InstallRoot $Version
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Write-Output "Extracting to $dest ..."
Expand-Archive -Path $tempZip -DestinationPath $dest -Force

# Verify terraform.exe exists
$tfExe = Join-Path $dest "terraform.exe"
if (-not (Test-Path $tfExe)) {
    Write-ErrAndExit "terraform.exe not found after extraction."
}

# Decide scope for PATH update
$desiredScope = "User"
if ($MachinePath) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-ErrAndExit "Adding to Machine PATH requires Administrator. Rerun the script elevated or omit -MachinePath."
    }
    $desiredScope = "Machine"
}

# Add install folder to PATH if missing
$currentPath = [Environment]::GetEnvironmentVariable("Path", $desiredScope)
if ($currentPath -notlike "*$dest*") {
    $newPath = $currentPath + ";" + $dest
    [Environment]::SetEnvironmentVariable("Path", $newPath, $desiredScope)
    Write-Output "Added $dest to $desiredScope PATH. You may need to restart your shell (or log off/on) to pick up changes."
} else {
    Write-Output "$dest already present in $desiredScope PATH."
}

# Cleanup
Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue

# Verify installation by running terraform -version from the installed path
Write-Output "Verifying terraform installation..."
& $tfExe -version

Write-Output "Done. If verification succeeded, run 'terraform -version' in a new shell."

