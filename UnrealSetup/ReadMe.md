# Unreal Engine Development Environment Setup

![Version](https://img.shields.io/badge/version-5.1.0-blue.svg) ![Last Updated](https://img.shields.io/badge/last_updated-February_21,_2025-green.svg) ![License](https://img.shields.io/badge/license-MIT-yellow.svg)

This PowerShell script, authored by **Mohamed Elsherbiny**, automates the creation of an optimized development environment for Unreal Engine (UE) on Windows. Tailored for artists and developers, it installs essential tools, configures system settings, and streamlines workflows for Unreal Engine projects as of **February 21, 2025**.

---

## Table of Contents

- [Unreal Engine Development Environment Setup](#unreal-engine-development-environment-setup)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [Step-by-Step Guide](#step-by-step-guide)
    - [Installation Notes](#installation-notes)
  - [Usage](#usage)
    - [Running the Script](#running-the-script)
    - [Configuration Options](#configuration-options)
    - [Backup and Restore](#backup-and-restore)
  - [Components](#components)
    - [Tool Installation](#tool-installation)
    - [Environment Configuration](#environment-configuration)
    - [Validation](#validation)
  - [Directory Structure](#directory-structure)
  - [PowerShell Profile Enhancements](#powershell-profile-enhancements)
  - [Compatibility](#compatibility)
  - [Troubleshooting](#troubleshooting)
  - [Contributing](#contributing)
  - [License](#license)

---

## Overview

The **Unreal Engine Development Environment Setup** script simplifies the process of preparing a Windows system for Unreal Engine development. By leveraging [Chocolatey](https://chocolatey.org/), a robust package manager, it automates the installation of tools, configures Git, sets up environment variables, and enhances PowerShell with Unreal-specific utilities. Supporting Unreal Engine versions **4.27 to 5.4**, it ensures compatibility with required Visual Studio versions, workloads, and .NET SDKs.

This script is ideal for:

- **Developers**: Setting up coding environments with Git, Visual Studio, and Unreal extras.
- **Artists**: Installing tools like Blender, Substance Painter, and Maya for asset creation.
- **Teams**: Standardizing development setups across multiple machines.

---

## Features

- **Multi-Version Support**: Configure environments for Unreal Engine 4.27, 5.0, 5.1, 5.2, 5.3, and 5.4.
- **Automated Tool Installation**: Installs development tools (e.g., Git, VS Code), artist tools (e.g., Blender, Maya), and Unreal extras (e.g., UE4CLI, Rider).
- **Environment Configuration**: Sets up Git, environment variables, and a PowerShell profile with Unreal-specific aliases and functions.
- **Backup System**: Creates backups of the current environment before changes.
- **Parallel Installation**: Speeds up setup with optional parallel package installations.
- **Validation**: Verifies tool and Unreal Engine component installations.
- **Customizable**: Offers interactive prompts to tailor the setup to user needs.
- **Logging**: Detailed logs for troubleshooting and verification.

---

## Requirements

- **Operating System**: Windows 10 or later (64-bit)
- **PowerShell**: Version 5.1 or higher (PowerShell Core supported)
- **Administrator Privileges**: Script must run with elevated permissions (`-RunAsAdministrator`)
- **Internet Connection**: Required for downloading Chocolatey and packages
- **Disk Space**: Minimum 50 GB free (varies based on tools and UE versions installed)

---

## Installation

### Step-by-Step Guide

1. **Download the Script**:

   - Clone the repository or download `UnrealEngineSetup.ps1`:
     ```bash
     git clone <repository-url>
     cd <repository-folder>
     ```

2. **Open PowerShell as Administrator**:

   - Right-click the Start menu → "Windows PowerShell (Admin)" or "Terminal (Admin)".

3. **Set Execution Policy** (if needed):

   - Allow script execution:
     ```powershell
     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
     ```

4. **Run the Script**:

   - Execute from the script directory:
     ```powershell
     .\UnrealEngineSetup.ps1
     ```

5. **Follow Interactive Prompts**:
   - Customize your setup (e.g., UE versions, tools) or accept defaults.

### Installation Notes

- The script installs Chocolatey if not present.
- Logs are saved to `%TEMP%\UnrealEngineSetup_YYYYMMDD_HHmmss.log`.

---

## Usage

### Running the Script

Run in an elevated PowerShell session:

```powershell
.\UnrealEngineSetup.ps1
```

The script will:

1. Display a welcome banner.
2. Prompt for configuration options (or use defaults if `PromptForChoices = $false`).
3. Install tools and configure the environment.
4. Validate the setup and provide a summary.

### Configuration Options

Interactive prompts allow customization:

- **Unreal Engine Versions**: Select one or more (e.g., "5.4", "all").
- **Software Installation**:
  - Visual Studio (version based on UE compatibility)
  - Epic Games Launcher
  - Development Tools (e.g., Git, VS Code, Docker)
  - Artist Tools (e.g., Blender, Substance Painter)
  - Unreal Extras (e.g., UE4CLI, Rider)
- **Environment Setup**:
  - Configure Git for Unreal Engine
  - Create directory structure
  - Set up PowerShell profile
  - Enable backups and validation
  - Use parallel installations

### Backup and Restore

- **Backup**: Enabled by default, saves environment settings (PATH, variables, profile) to `~/UnrealSetupBackup/EnvBackup_YYYYMMDD_HHMMSS.json`.
- **Restore**: Manually restore using:
  ```powershell
  Restore-Environment -BackupPath "$env:USERPROFILE\UnrealSetupBackup"
  ```

---

## Components

### Tool Installation

Uses Chocolatey to install:

- **Visual Studio**: UE 4.x (2019), UE 5.x (2022) with required workloads.
- **Epic Games Launcher**: For UE version management.
- **Development Tools**: Git, VS Code, Docker, Node.js, CMake, etc.
- **Artist Tools**: Blender, Maya, Substance Painter, Quixel Bridge, etc.
- **Unreal Extras**: UE4CLI, Rider, .NET SDKs.
- **Python Dependencies**: Packages like `unreal`, `numpy`, `opencv-python`.

### Environment Configuration

- **Git**: Optimized with `core.autocrlf true`, Git LFS, and long path support.
- **Directories**: Structured under `~/Projects` (see [Directory Structure](#directory-structure)).
- **Environment Variables**: Sets `UE_ROOT`, `UE_PROJECTS`, `PYTHON_HOME`, etc.
- **PowerShell Profile**: Adds aliases and functions (see [PowerShell Profile Enhancements](#powershell-profile-enhancements)).

### Validation

- Verifies tools (e.g., Git, Python, Blender).
- Checks Unreal Engine installations in `C:\Program Files\Epic Games`.
- Confirms environment variable settings.

---

## Directory Structure

Created under `$env:USERPROFILE`:

```
~/Projects/
├── UnrealProjects/    # UE project files
├── UnrealPlugins/     # Custom plugins
├── UnrealAssets/      # Asset storage
├── UnrealPrototypes/  # Prototype projects
├── UnrealTools/       # Tool scripts
~/Workspace/           # General workspace
~/GitHub/              # Git repositories
~/.ssh/                # SSH keys
~/.config/             # Configuration files
~/.docker/             # Docker configurations
~/Downloads/Development/ # Development downloads
```

---

## PowerShell Profile Enhancements

Enhances `$PROFILE` with:

- **Aliases**:
  - `ue4`, `ue5`, `ue`: Navigate to UE directories.
  - `ueprojects`, `ueassets`, `ueplugins`: Jump to project folders.
  - `gs`, `gp`, `gcm`: Git shortcuts.
- **Functions**:
  - `Get-UnrealEngineVersions`: Lists installed UE versions.
  - `Start-UEEditor`: Launches the Unreal Editor.
  - `New-UEProject`: Creates a new project with a template.
  - `Build-UEProject`: Builds a project from a `.uproject` file.

**Example Usage**:

```powershell
New-UEProject -ProjectName "MyGame" -EngineVersion "5.4"
Start-UEEditor -Version "5.4"
Build-UEProject -ProjectPath "C:\Users\Username\Projects\UnrealProjects\MyGame"
```

---

## Compatibility

Matches tools to Unreal Engine versions:

| UE Version | Visual Studio     | .NET SDKs     | VCRedist     |
| ---------- | ----------------- | ------------- | ------------ |
| 4.27       | VS 2019 Community | 5.0           | vcredist140  |
| 5.0-5.4    | VS 2022 Community | 6.0, 7.0, 8.0 | vcredist-all |

---

## Troubleshooting

- **Script Won’t Run**: Ensure Administrator mode and `Bypass` execution policy.
- **Chocolatey Fails**: Verify internet connection; retry with `choco upgrade chocolatey -y`.
- **Tool Missing**: Check `%TEMP%\UnrealEngineSetup_YYYYMMDD_HHmmss.log`.
- **UE Not Installed**: Use Epic Games Launcher post-setup to install versions.
- **Restore Issues**: Confirm backup exists in `~/UnrealSetupBackup`.

For detailed logs, see `%TEMP%\UnrealEngineSetup_YYYYMMDD_HHmmss.log`.

---

## Contributing

Contributions are encouraged! To contribute:

1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature/new-tool
   ```
3. Commit changes:
   ```bash
   git commit -m "Add support for new tool"
   ```
4. Push to the branch:
   ```bash
   git push origin feature/new-tool
   ```
5. Open a Pull Request.

Follow PowerShell best practices and include comments.

---

## License

Licensed under the MIT License by **Mohamed Elsherbiny**. See [LICENSE](LICENSE) for details.

**Copyright © 2025 Mohamed Elsherbiny**
