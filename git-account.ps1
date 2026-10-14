<#
.SYNOPSIS
    CLI manager for switching and inspecting Git accounts for a repository.
.DESCRIPTION
    Usage:
        .\git-account.ps1 [status]
        .\git-account.ps1 switch
        .\git-account.ps1 personal
        .\git-account.ps1 work
#>
param (
    [Parameter(Position=0)]
    [ValidateSet("status", "switch", "personal", "work", "set-work", "set-personal", "show-config", "config", "help")]
    [string]$Action = "status",

    [Parameter(Position=1)]
    [string]$Email = "",

    [Parameter(Position=2)]
    [string]$Name = ""
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pickerScript = Join-Path $scriptDir "git-account-picker.ps1"
$configFile = Join-Path $scriptDir "config.json"
$repoPath = (Get-Location).Path

function Get-RepoRemote {
    try {
        $remote = git remote get-url origin 2>$null
        return $remote
    } catch {
        return ""
    }
}

function Show-Status {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "                GIT ACCOUNT STATUS                         " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $isRepo = Test-Path (Join-Path $repoPath ".git")
    if (-not $isRepo) {
        Write-Host "Current Directory: $repoPath (Not a Git repository)" -ForegroundColor Yellow
        return
    }

    $remote = Get-RepoRemote
    $localAccount = git config --local user.account 2>$null
    $localName = git config --local user.name 2>$null
    $localEmail = git config --local user.email 2>$null
    $localHelper = git config --local credential.helper 2>$null

    Write-Host "Repository Path    : " -NoNewline; Write-Host $repoPath -ForegroundColor White
    Write-Host "Remote URL (origin): " -NoNewline; Write-Host ($remote -or "(None)") -ForegroundColor Magenta
    Write-Host "Active Account     : " -NoNewline; Write-Host ($localAccount -or "Not configured (will prompt on push)") -ForegroundColor $(if ($localAccount) { "Green" } else { "Yellow" })
    Write-Host "User Name          : " -NoNewline; Write-Host ($localName -or "(inherited from global)") -ForegroundColor White
    Write-Host "User Email         : " -NoNewline; Write-Host ($localEmail -or "(inherited from global)") -ForegroundColor White
    Write-Host "Credential Helper  : " -NoNewline; Write-Host ($localHelper -or "(inherited from global)") -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Cyan
}

switch ($Action) {
    "status" {
        Show-Status
    }
    "switch" {
        $remote = Get-RepoRemote
        if ([string]::IsNullOrWhiteSpace($remote)) {
            $remote = ""
        }
        & "$pickerScript" -RepoPath "$repoPath" -RemoteUrl "$remote" -ConfigFilePath "$configFile"
        Show-Status
    }
    "personal" {
        if (Test-Path $configFile) {
            $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
            git config --local user.account "personal"
            git config --local user.name "$($cfg.personal.name)"
            git config --local user.email "$($cfg.personal.email)"
            Write-Host "Switched to Personal account ($($cfg.personal.email))." -ForegroundColor Green
        }
    }
    "work" {
        if (Test-Path $configFile) {
            $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
            git config --local user.account "work"
            git config --local user.name "$($cfg.work.name)"
            if ($cfg.work.email) {
                git config --local user.email "$($cfg.work.email)"
            }
            git config --local credential.helper "manager"
            Write-Host "Switched to Work account ($($cfg.work.email))." -ForegroundColor Green
        }
    }
    "set-work" {
        if (-not (Test-Path $configFile)) {
            Write-Error "Config file not found: $configFile"
            return
        }
        $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
        if (-not [string]::IsNullOrWhiteSpace($Email)) { $cfg.work.email = $Email }
        if (-not [string]::IsNullOrWhiteSpace($Name)) { $cfg.work.name = $Name }
        $cfg | ConvertTo-Json -Depth 4 | Set-Content $configFile -Encoding UTF8
        Write-Host "✅ Work profile updated in config.json:" -ForegroundColor Green
        Write-Host "   Name : $($cfg.work.name)"
        Write-Host "   Email: $($cfg.work.email)"
    }
    "set-personal" {
        if (-not (Test-Path $configFile)) {
            Write-Error "Config file not found: $configFile"
            return
        }
        $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
        if (-not [string]::IsNullOrWhiteSpace($Email)) { $cfg.personal.email = $Email }
        if (-not [string]::IsNullOrWhiteSpace($Name)) { $cfg.personal.name = $Name }
        $cfg | ConvertTo-Json -Depth 4 | Set-Content $configFile -Encoding UTF8
        Write-Host "✅ Personal profile updated in config.json:" -ForegroundColor Green
        Write-Host "   Name : $($cfg.personal.name)"
        Write-Host "   Email: $($cfg.personal.email)"
    }
    "show-config" {
        if (Test-Path $configFile) {
            Get-Content $configFile
        } else {
            Write-Host "Config file does not exist yet." -ForegroundColor Yellow
        }
    }
    "config" {
        Start-Process notepad.exe -ArgumentList "`"$configFile`""
    }
    "help" {
        Write-Host "Git Account Switcher & Configuration:" -ForegroundColor Cyan
        Write-Host "  .\git-account.ps1 status                 - Display current repo Git identity"
        Write-Host "  .\git-account.ps1 switch                 - Open the interactive GUI popup to switch"
        Write-Host "  .\git-account.ps1 personal               - Quick switch to personal profile"
        Write-Host "  .\git-account.ps1 work                   - Quick switch to work profile"
        Write-Host "  .\git-account.ps1 set-work <email> [name]    - Update work profile email/name in config.json"
        Write-Host "  .\git-account.ps1 set-personal <email> [name]- Update personal profile email/name in config.json"
        Write-Host "  .\git-account.ps1 show-config            - Print current config.json"
        Write-Host "  .\git-account.ps1 config                 - Open config.json in Notepad"
    }
}
