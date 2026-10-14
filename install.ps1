<#
.SYNOPSIS
    Installs and configures Git Multi-Account Manager.
.DESCRIPTION
    1. Prompts for or verifies work email and personal email.
    2. Configures Git Credential Manager for multi-account Azure DevOps and GitHub.
    3. Sets global core.hooksPath so all repositories trigger the pre-push check automatically.
#>
param (
    [string]$PersonalEmail = "",
    [string]$WorkEmail = ""
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       GIT MULTI-ACCOUNT MANAGER - INSTALLER              " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configFile = Join-Path $scriptDir "config.json"
$hooksDir = Join-Path $scriptDir "hooks"

$exampleConfigFile = Join-Path $scriptDir "config.example.json"

# If config.json does not exist, copy from config.example.json
if (-not (Test-Path $configFile) -and (Test-Path $exampleConfigFile)) {
    Copy-Item $exampleConfigFile $configFile
    Write-Host "Created config.json from config.example.json template." -ForegroundColor Gray
}

# Load existing config if available
$cfg = @{
    personal = @{
        name = "Personal User"
        email = ""
        domains = @("github.com")
    }
    work = @{
        name = "Work User"
        email = ""
        domains = @("dev.azure.com", "visualstudio.com")
    }
}

if (Test-Path $configFile) {
    try {
        $loaded = Get-Content $configFile -Raw | ConvertFrom-Json
        if ($loaded.personal.email) { $cfg.personal.email = $loaded.personal.email }
        if ($loaded.personal.name) { $cfg.personal.name = $loaded.personal.name }
        if ($loaded.work.email) { $cfg.work.email = $loaded.work.email }
        if ($loaded.work.name) { $cfg.work.name = $loaded.work.name }
    } catch {}
}

if (-not [string]::IsNullOrWhiteSpace($PersonalEmail)) {
    $cfg.personal.email = $PersonalEmail
}
if (-not [string]::IsNullOrWhiteSpace($WorkEmail)) {
    $cfg.work.email = $WorkEmail
}

# If work email is still blank and running interactively, ask
if ([string]::IsNullOrWhiteSpace($cfg.work.email) -and -not [string]::IsNullOrWhiteSpace($WorkEmail)) {
    $cfg.work.email = $WorkEmail
}

# Save updated config
$cfg | ConvertTo-Json -Depth 4 | Set-Content $configFile -Encoding UTF8
Write-Host "[1/3] Configured config.json:" -ForegroundColor Green
Write-Host "      Personal: $($cfg.personal.name) <$($cfg.personal.email)>"
Write-Host "      Work    : $($cfg.work.name) <$($cfg.work.email)>"

# Step 2: Configure Git Credential Manager for Azure DevOps
Write-Host "[2/3] Configuring Git Credential Manager (GCM)..." -ForegroundColor Green
# For Azure DevOps, ensure usehttppath and manager are enabled
git config --global credential.https://dev.azure.com.useHttpPath true
git config --global credential.https://visualstudio.com.useHttpPath true

# Step 3: Configure global hooks path with forward slashes for Git compatibility
$gitHooksPath = $hooksDir.Replace('\', '/')
Write-Host "[3/3] Setting global core.hooksPath to $gitHooksPath..." -ForegroundColor Green
git config --global core.hooksPath "$gitHooksPath"

# Step 4: Add folder to User PATH so 'git-account' is available globally in any terminal
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$scriptDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$scriptDir", "User")
    Write-Host "[4/4] Added $scriptDir to User PATH environment variable." -ForegroundColor Green
    Write-Host "      (You can now run 'git-account' from any terminal window)" -ForegroundColor Gray
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "Global hook is active. Any 'git push' across all repositories will now verify your account." -ForegroundColor White
Write-Host "To inspect or switch an account anytime in any folder, type: git-account" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
