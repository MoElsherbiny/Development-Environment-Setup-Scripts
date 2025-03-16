# Windows Development Environment Setup

![Version](https://img.shields.io/badge/version-5.1.4-blue.svg) ![Last Updated](https://img.shields.io/badge/last_updated-March_15,_2025-green.svg) ![License](https://img.shields.io/badge/license-MIT-yellow.svg)

This PowerShell script, authored by **Mohamed Elsherbiny**, automates the setup of a robust development environment on Windows using **Scoop** and **winget**. It installs essential tools, configures system settings, and enhances workflows for developers as of **March 15, 2025**.

---

## Table of Contents

- [Windows Development Environment Setup](#windows-development-environment-setup)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Features](#features)
  - [Requirements](#requirements)
    - [Windows](#windows)
    - [macOS (Conceptual)](#macos-conceptual)
    - [Linux (Conceptual)](#linux-conceptual)
  - [Installation](#installation)
    - [Windows](#windows-1)
    - [macOS (Conceptual)](#macos-conceptual-1)
    - [Linux (Conceptual)](#linux-conceptual-1)
  - [Configuration](#configuration)
  - [Customization](#customization)
    - [VS Code Extensions](#vs-code-extensions)
    - [Environment Variables](#environment-variables)
    - [Tool Selection](#tool-selection)
  - [Maintenance](#maintenance)
  - [Troubleshooting](#troubleshooting)
    - [Common Issues](#common-issues)
  - [Logging](#logging)
  - [Uninstallation](#uninstallation)
  - [Contributing](#contributing)
  - [Disclaimer](#disclaimer)
  - [Granting PowerShell Full Control via Registry Editor](#granting-powershell-full-control-via-registry-editor)
    - [When Needed](#when-needed)
    - [Steps](#steps)
    - [Verification](#verification)
    - [Reverting Changes](#reverting-changes)
    - [Security Note](#security-note)
  - [License](#license)

---

## Overview

The **Windows Development Environment Setup** script streamlines the process of configuring a Windows system for software development. It leverages Scoop and winget to install a wide range of tools, sets up environment variables, configures Git, enhances PowerShell with shortcuts, and integrates with Visual Studio Code and Windows Terminal. Designed for developers, it supports programming languages, DevOps tools, and cloud CLIs, ensuring a consistent and efficient setup.

This guide provides instructions for Windows (based on the provided script) and conceptual steps for macOS and Linux, assuming analogous scripts exist.

---

## Features

- **Package Management**: Uses Scoop and winget for efficient tool installation on Windows.
- **Tool Installation**:
  - Version control (Git)
  - Languages (Node.js, Python, Go, Rust, Java, Ruby, etc.)
  - DevOps tools (Docker, Kubernetes, Terraform, AWS CLI, Azure CLI)
  - Editors/IDEs (VS Code)
  - Databases (MySQL, PostgreSQL, MongoDB, Redis)
  - Utilities (7zip, curl, PowerToys, Oh My Posh)
- **Environment Configuration**:
  - PATH management
  - Git configuration optimized for development
  - Directory structure for projects
  - VS Code settings and extensions
  - Windows Terminal customization
  - PowerShell profile with aliases and functions
- **Automation**:
  - Scheduled weekly updates via Task Scheduler
  - Manual update function (`Update-DevEnv`)
  - Self-healing PATH verification
- **Logging**: Detailed logs for auditing and troubleshooting.

---

## Requirements

### Windows

- **OS**: Windows 10/11 (64-bit)
- **PowerShell**: Version 5.1 or later
- **Privileges**: Administrator access (`-RunAsAdministrator`)
- **Internet**: Required for package downloads
- **Disk Space**: ~20 GB free (varies by tools installed)

### macOS (Conceptual)

- **OS**: macOS 10.15 (Catalina) or later
- **Shell**: Bash/Zsh
- **Privileges**: Admin access
- **Package Manager**: Homebrew (installed if missing)

### Linux (Conceptual)

- **OS**: Ubuntu/Debian or Fedora/RHEL
- **Shell**: Bash
- **Privileges**: sudo access
- **Package Manager**: apt (Debian/Ubuntu) or dnf (Fedora/RHEL)

---

## Installation

### Windows

1. **Download the Script**:

   - Clone or download `WindowsDevEnv-Setup.ps1`:
     ```powershell
     git clone <repository-url>
     cd <repository-folder>
     ```

2. **Open PowerShell as Administrator**:

   - Right-click Start → "Windows PowerShell (Admin)" or "Terminal (Admin)".

3. **Set Execution Policy** (if needed):

   - Enable script execution:
     ```powershell
     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
     ```

4. **Run the Script**:

   - Navigate to the script folder and execute:
     ```powershell
     .\WindowsDevEnv-Setup.ps1
     ```

5. **Follow Prompts**:
   - Confirm optional tool installations (e.g., browsers).

### macOS (Conceptual)

1. **Open Terminal**:

   - Launch via Spotlight (`Cmd + Space`) → "Terminal".

2. **Download and Run**:

   - Fetch and execute a macOS-specific script:
     ```bash
     curl -O https://<repository-url>/macos-dev-setup.sh
     chmod +x macos-dev-setup.sh
     ./macos-dev-setup.sh
     ```

3. **Install Homebrew** (if missing):
   - Script will run:
     ```bash
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
     ```

### Linux (Conceptual)

1. **Open Terminal**:

   - Press `Ctrl + Alt + T` or use the app menu.

2. **Download and Run**:

   - Fetch and execute a Linux-specific script:
     ```bash
     curl -O https://<repository-url>/linux-dev-setup.sh
     chmod +x linux-dev-setup.sh
     sudo ./linux-dev-setup.sh
     ```

3. **Update Package Manager**:
   - Script will run:
     ```bash
     sudo apt update  # Ubuntu/Debian
     sudo dnf check-update  # Fedora/RHEL
     ```

---

## Configuration

The script automatically configures:

- **VS Code**: Default settings (e.g., FiraCode NF font), essential extensions (e.g., PowerShell, Python, Docker).
- **Windows Terminal**: FiraCode NF font, One Half Dark scheme.
- **Git**: Global settings (e.g., `core.autocrlf true`, `credential.helper wincred`).
- **Environment Variables**: Sets `PYTHON_HOME`, `NODE_PATH`, `GOPATH`, etc.
- **PowerShell Profile**: Adds aliases (e.g., `gs`, `gp`) and functions (e.g., `Update-DevEnv`, `cdp`).
- **Directories**: Creates `Projects`, `Workspace`, `GitHub`, etc.

---

## Customization

### VS Code Extensions

- Edit `$essentialExtensions` in the script or create an `extensions.txt` file with extension IDs:
  ```
  ms-vscode.csharp
  redhat.vscode-yaml
  ```

### Environment Variables

- Modify `$envVars` in the script:
  ```powershell
  $envVars['MY_CUSTOM_VAR'] = "C:\Custom\Path"
  ```

### Tool Selection

- Adjust `$scoopApps` array to include/exclude tools or mark as `optional`.

---

## Maintenance

- **Scheduled Updates**: Runs weekly via Task Scheduler (Mondays, 9 AM) to update tools.
- **Manual Update**:
  ```powershell
  Update-DevEnv
  ```
- **Package Updates**: Updates Scoop, npm, pip, and winget packages automatically.

---

## Troubleshooting

### Common Issues

1. **Script Fails to Run**:
   - Ensure Administrator privileges and correct execution policy.
   - Run: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force`
2. **Scoop Installation Fails**:
   - Check internet; retry with: `irm get.scoop.sh -RunAsAdmin | iex`
3. **Tool Not in PATH**:
   - Verify `$paths` array and run `Test-AllPaths`.
4. **Internet Issues**:
   - Confirm connectivity to `8.8.8.8` or adjust proxy settings.
5. **Log Review**:
   - Check `%TEMP%\dev-setup-YYYYMMDD-HHmmss.log`.

---

## Logging

- **Location**: `%TEMP%\dev-setup-YYYYMMDD-HHmmss.log`
- **Summary Report**: `%TEMP%\dev-setup-summary-YYYYMMDD-HHmmss.txt`
- **Details**: Tracks installations, failures, skips, and validation results.

---

## Uninstallation

1. **Remove Tools**:
   - Scoop: `scoop uninstall <tool>`
   - Winget: `winget uninstall --id <wingetId>`
2. **Delete Directories**:
   - Remove `~/scoop`, `~/Projects`, etc.
3. **Reset Environment**:
   - Remove `$envVars` entries via System Properties → Environment Variables.
4. **Remove Scheduled Task**:
   - `Unregister-ScheduledTask -TaskName "DevelopmentEnvironmentUpdate"`

---

## Contributing

Contributions welcome! To contribute:

1. Fork the repository.
2. Create a branch: `git checkout -b feature/new-tool`
3. Commit changes: `git commit -m "Add new tool"`
4. Push: `git push origin feature/new-tool`
5. Open a Pull Request.

---

## Disclaimer

This script modifies system settings and installs software. Review the code before running. The author is not liable for system issues or data loss. Use in development environments only, not production.

---

## Granting PowerShell Full Control via Registry Editor

### When Needed

- Required if execution policies remain restrictive despite `Set-ExecutionPolicy`.
- Useful in locked-down environments (e.g., corporate systems).

### Steps

1. **Open Registry Editor**:
   - `Win + R` → `regedit` → Yes (UAC prompt).
2. **Navigate to PowerShell Key**:
   - `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell`
   - If missing, right-click `Windows` → New → Key → Name it `PowerShell`.
3. **Enable Scripts**:
   - Right-click `PowerShell` → New → DWORD (32-bit) Value → Name: `EnableScripts` → Value: `1`.
4. **Grant Permissions**:
   - Navigate: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`
   - Right-click `Environment` → Permissions → Add → `SYSTEM` → Full Control → Apply.
5. **Restart**:
   - Reboot to apply changes.

### Verification

- Run: `Get-ExecutionPolicy -List`
- Expected: `MachinePolicy`/`UserPolicy` as `Unrestricted` or `RemoteSigned`.
- Test: `.\WindowsDevEnv-Setup.ps1`

### Reverting Changes

1. **Remove EnableScripts**:
   - Delete `EnableScripts` from `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell`.
2. **Reset Permissions**:
   - Remove `SYSTEM` Full Control from `Environment` key.
3. **Restore Policy**:
   - `Set-ExecutionPolicy Restricted -Scope LocalMachine -Force`

### Security Note

- Full control increases risk; use only in trusted environments with reviewed scripts.

---

## License

Licensed under the MIT License by **Mohamed Elsherbiny**. See [LICENSE](LICENSE) for details.

**Copyright © 2025 Mohamed Elsherbiny**
