# Git Multi-Account Manager

A lightweight, automated solution for managing dual Git identities (**Personal GitHub** and **Work Azure DevOps / Microsoft**) on a single Windows development machine.

## How It Works

1. **Global `pre-push` Hook**:
   Every time you run `git push`, the hook inspects the current repository:
   - If the repository has already been configured with an identity (`user.account`) and matches the target remote, the push proceeds instantly without interruption.
   - If the repository has **not been configured yet**, or if there is a **mismatch** (e.g. pushing to an Azure DevOps remote using your Personal identity), a sleek native Windows dark-mode GUI popup appears.

2. **Interactive GUI Selector**:
   - Displays the remote destination URL.
   - Recommends the matching profile (**Personal** for GitHub, **Work** for Azure DevOps).
   - Allows selecting either account and checking **"Remember this choice in local repository config"**.
   - Clicking **"Apply & Continue"** sets `user.name`, `user.email`, and `user.account` in the repository's `.git/config` and resumes the push.
   - Clicking **"Cancel Push"** safely aborts the push without touching anything.

3. **Per-Repository Isolation**:
   Because choices are saved to `.git/config` (local repo config), your personal and work repositories never cross-contaminate.

---

## Files

- [git-account-picker.ps1](file:///c:/Users/Abhijeet%20Ranjan/Desktop/code/personal/generative-ai/git-manager/git-account-picker.ps1): Native Windows WPF modal dialog.
- [git-account.ps1](file:///c:/Users/Abhijeet%20Ranjan/Desktop/code/personal/generative-ai/git-manager/git-account.ps1): CLI tool to inspect status or switch accounts at any time.
- [git-account.cmd](file:///c:/Users/Abhijeet%20Ranjan/Desktop/code/personal/generative-ai/git-manager/git-account.cmd): Batch wrapper allowing `git-account` command anywhere.
- [hooks/pre-push](file:///c:/Users/Abhijeet%20Ranjan/Desktop/code/personal/generative-ai/git-manager/hooks/pre-push): Git pre-push hook script.
- [config.example.json](file:///c:/Users/Abhijeet%20Ranjan/Desktop/code/personal/generative-ai/git-manager/config.example.json): Template configuration file (safe to commit).
- [config.json](file:///c:/Users/Abhijeet%20Ranjan/Desktop/code/personal/generative-ai/git-manager/config.json): Your local personal/work configuration (ignored in git via `.gitignore`).
- [install.ps1](file:///c:/Users/Abhijeet%20Ranjan/Desktop/code/personal/generative-ai/git-manager/install.ps1): One-click installer.

---

## Setup & Installation

### Step 1: Configure Your Account Details
Before or after installation, you must configure your personal and work profiles:
1. Copy `config.example.json` to `config.json` (if not done already):
   ```powershell
   Copy-Item config.example.json config.json
   ```
2. Update `config.json` with your real personal and work email/name:
   - Either edit `config.json` directly in your editor.
   - Or run via CLI:
     ```powershell
     .\git-account.ps1 set-personal -Email "your.personal@email.com" -Name "Your Name"
     .\git-account.ps1 set-work -Email "your.work@company.com" -Name "Your Name"
     ```

> [!NOTE]
> `config.json` is automatically ignored in [.gitignore](file:///c:/Users/Abhijeet%20Ranjan/Desktop/code/personal/generative-ai/git-manager/.gitignore) so your private company and personal email addresses will never be accidentally committed to GitHub.

### Step 2: Run the Installer
Run the installer from PowerShell:
```powershell
.\install.ps1
```

> [!TIP]
> Windows updates the User `PATH` environment variable during install. To use `git-account` from any folder, restart your terminal window or open a new tab so the updated PATH takes effect. In the current session, you can run `.\git-account.ps1` or reload PATH with `$env:Path = [System.Environment]::GetEnvironmentVariable("Path","User") + ";" + [System.Environment]::GetEnvironmentVariable("Path","Machine")`.

### What this does automatically:
1. **Configures Git Credential Manager (GCM)** for Azure DevOps (`useHttpPath = true`) so Microsoft SSO and GitHub logins don't conflict.
2. **Registers the global Git hook** (`git config --global core.hooksPath ...`) so **every** current and future repository automatically has push protection.
3. **Adds this folder to your User PATH**, allowing you to run `git-account` from **any** terminal or repository without typing `.\` or file paths.

---

## Sharing With Team Members

To share this tool with teammates:
1. Push/share this repository to your GitHub.
2. Teammates clone it anywhere on their PC (e.g. `C:\tools\git-manager` or `~\git-manager`).
3. They copy `config.example.json` to `config.json` (or pass parameters to `install.ps1`):
   ```powershell
   .\install.ps1 -WorkEmail "their.email@company.com" -PersonalEmail "their.personal@email.com"
   ```
4. Everything is ready! They now have the same GUI popup, account switcher, and push protection across their entire laptop.
---

## CLI Usage

Inspect repository status:
```powershell
.\git-account.ps1 status
```

Open the GUI picker to switch or verify account:
```powershell
.\git-account.ps1 switch
```

Quick-switch directly in current repo:
```powershell
.\git-account.ps1 personal
.\git-account.ps1 work
```

Update account profiles in `config.json` via CLI:
```powershell
# Set work email and name:
.\git-account.ps1 set-work -Email "your.name@company.com" -Name "Abhijeet Ranjan"

# Set personal email and name:
.\git-account.ps1 set-personal -Email "ranjan.viper@outlook.com" -Name "Abhijeet Ranjan"

# View current configuration:
.\git-account.ps1 show-config

# Or open config.json directly in Notepad:
.\git-account.ps1 config
```

---

## Safety Guarantees
- Never pushes blindly to `dev.azure.com` or `github.com` without confirming the correct identity.
- No third-party binaries or services needed; pure PowerShell WPF and standard Git hooks.
