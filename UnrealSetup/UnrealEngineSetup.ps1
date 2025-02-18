# Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script version and timestamp
$SCRIPT_VERSION = "5.0.0"
$SCRIPT_TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

#region Configuration

# Default configuration
$defaultConfig = @{
  # Core settings
  PromptForChoices         = $true
  ValidateInstallation     = $true
  CreateBackup             = $true

  # Installation options
  InstallVisualStudio      = $true
  InstallEpicGamesLauncher = $true
  InstallArtistTools       = $true
  InstallDevTools          = $true
  InstallTextureTools      = $true
  Install3DModeling        = $true

  # Unreal Engine specific
  UnrealEngineVersions     = @("4.27", "5.0", "5.1", "5.2", "5.3")
  DefaultUnrealVersion     = "5.3"

  # Environment setup
  SetupGitConfiguration    = $true
  CreateDirectories        = $true
  SetupPowershellProfile   = $true

  # Paths
  BackupPath               = (Join-Path $env:USERPROFILE "UnrealSetupBackup")
  LogPath                  = (Join-Path $env:TEMP "UnrealEngineSetup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log")
}

# Compatibility database for tool versions based on Unreal Engine version
$compatibilityDB = @{
  "4.27" = @{
    VisualStudio   = "visualstudio2019community"
    VSWorkloads    = @(
      'visualstudio2019-workload-nativedesktop',
      'visualstudio2019-workload-manageddesktop',
      'visualstudio2019-workload-universalplatform',
      'visualstudio2019-workload-nativegame'
    )
    DotNetVersions = @('dotnet-sdk', 'dotnet-5.0-sdk')
    VCRedist       = 'vcredist140'
  }
  "5.0"  = @{
    VisualStudio   = "visualstudio2022community"
    VSWorkloads    = @(
      'visualstudio2022-workload-nativedesktop',
      'visualstudio2022-workload-manageddesktop',
      'visualstudio2022-workload-universal',
      'visualstudio2022-workload-nativegame'
    )
    DotNetVersions = @('dotnet-6.0-sdk', 'dotnet-5.0-sdk')
    VCRedist       = 'vcredist-all'
  }
  "5.1"  = @{
    VisualStudio   = "visualstudio2022community"
    VSWorkloads    = @(
      'visualstudio2022-workload-nativedesktop',
      'visualstudio2022-workload-manageddesktop',
      'visualstudio2022-workload-universal',
      'visualstudio2022-workload-nativegame'
    )
    DotNetVersions = @('dotnet-6.0-sdk', 'dotnet-5.0-sdk')
    VCRedist       = 'vcredist-all'
  }
  "5.2"  = @{
    VisualStudio   = "visualstudio2022community"
    VSWorkloads    = @(
      'visualstudio2022-workload-nativedesktop',
      'visualstudio2022-workload-manageddesktop',
      'visualstudio2022-workload-universal',
      'visualstudio2022-workload-nativegame'
    )
    DotNetVersions = @('dotnet-7.0-sdk', 'dotnet-6.0-sdk')
    VCRedist       = 'vcredist-all'
  }
  "5.3"  = @{
    VisualStudio   = "visualstudio2022community"
    VSWorkloads    = @(
      'visualstudio2022-workload-nativedesktop',
      'visualstudio2022-workload-manageddesktop',
      'visualstudio2022-workload-universal',
      'visualstudio2022-workload-nativegame'
    )
    DotNetVersions = @('dotnet-8.0-sdk', 'dotnet-7.0-sdk')
    VCRedist       = 'vcredist-all'
  }
}

#endregion

#region Utility Functions

# Function to initialize logging
function Start-Logging {
  $script:LogFile = $defaultConfig.LogPath
  Start-Transcript -Path $LogFile -Append
  Write-Host "Logging to: $LogFile"
}

# Function to write colored output with timestamp and logging
function Write-ColorOutput {
  param(
    [string]$Message,
    [string]$Color = 'White',
    [switch]$NoNewLine,
    [switch]$LogOnly
  )
  $timestamp = Get-Date -Format "HH:mm:ss"
  $output = "[$timestamp] $Message"

  # Always write to log
  $output | Out-File -FilePath $LogFile -Append -Encoding UTF8

  # Write to console if not log-only
  if (-not $LogOnly) {
    if ($NoNewLine) {
      Write-Host $output -ForegroundColor $Color -NoNewline
    }
    else {
      Write-Host $output -ForegroundColor $Color
    }
  }
}

# Function to display a welcome banner
function Show-WelcomeBanner {
  Clear-Host
  $width = 78
  $banner = @"
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║      █ █ █▄ █ █▀█ █▀▀ ▄▀█ █   █▀▀ █▄ █ █▀▀ █ █▄ █ █▀▀   █▀ █▀▀ ▀█▀      ║
║      █▄█ █ ▀█ █▀▄ ██▄ █▀█ █▄▄ ██▄ █ ▀█ █▄█ █ █ ▀█ ██▄   ▄█ ██▄  █       ║
║                                                                          ║
║                        DEVELOPMENT ENVIRONMENT SETUP                     ║
║                                                                          ║
║                              Version $SCRIPT_VERSION                           ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
"@
  Write-Host $banner -ForegroundColor Cyan
  Write-Host "Started at: $SCRIPT_TIMESTAMP" -ForegroundColor Gray
  Write-Host ("=" * $width) -ForegroundColor DarkGray
  Write-Host "This script will set up a complete Unreal Engine development environment"
  Write-Host "tailored to your specific needs and preferences."
  Write-Host ("=" * $width) -ForegroundColor DarkGray
}

# Function to prompt for user choices
function Get-UserChoices {
  param (
    [hashtable]$Config
  )

  if (-not $Config.PromptForChoices) {
    return $Config
  }

  Write-Host "`nCONFIGURATION OPTIONS" -ForegroundColor Cyan
  Write-Host "===================="

  # Choose Unreal Engine version
  Write-Host "`n1. Select Unreal Engine Version(s)" -ForegroundColor Yellow
  $i = 1
  $versionChoices = @()
  foreach ($version in $Config.UnrealEngineVersions) {
    Write-Host "   $i. UE $version"
    $versionChoices += $version
    $i++
  }

  $selectedVersions = New-Object System.Collections.ArrayList

  do {
    $versionInput = Read-Host "Select Unreal Engine version(s) by number (comma-separated, or 'all')"
    if ($versionInput -eq 'all') {
      $selectedVersions = $Config.UnrealEngineVersions
      break
    }

    $selectedIndices = $versionInput -split ',' | ForEach-Object { [int]$_.Trim() - 1 }

    foreach ($index in $selectedIndices) {
      if ($index -ge 0 -and $index -lt $versionChoices.Count) {
        [void]$selectedVersions.Add($versionChoices[$index])
      }
    }
  } while ($selectedVersions.Count -eq 0)

  $Config.SelectedUnrealVersions = $selectedVersions

  # Software selection
  Write-Host "`n2. Select Software to Install" -ForegroundColor Yellow

  $Config.InstallVisualStudio = (Read-Host "Install Visual Studio? (y/n, default: y)").ToLower() -ne 'n'
  $Config.InstallEpicGamesLauncher = (Read-Host "Install Epic Games Launcher? (y/n, default: y)").ToLower() -ne 'n'
  $Config.InstallDevTools = (Read-Host "Install development tools (Git, VSCode, etc.)? (y/n, default: y)").ToLower() -ne 'n'

  # Artist tools
  $Config.InstallArtistTools = (Read-Host "Install artist tools? (y/n, default: y)").ToLower() -ne 'n'

  if ($Config.InstallArtistTools) {
    $Config.InstallTextureTools = (Read-Host "Install texture/material tools (Substance, Quixel, etc.)? (y/n, default: y)").ToLower() -ne 'n'
    $Config.Install3DModeling = (Read-Host "Install 3D modeling tools (Blender, Maya, etc.)? (y/n, default: y)").ToLower() -ne 'n'
  }

  # Environment setup
  Write-Host "`n3. Environment Setup" -ForegroundColor Yellow

  $Config.SetupGitConfiguration = (Read-Host "Configure Git for Unreal Engine? (y/n, default: y)").ToLower() -ne 'n'
  $Config.CreateDirectories = (Read-Host "Create recommended directory structure? (y/n, default: y)").ToLower() -ne 'n'
  $Config.SetupPowershellProfile = (Read-Host "Setup PowerShell profile with Unreal shortcuts? (y/n, default: y)").ToLower() -ne 'n'
  $Config.ValidateInstallation = (Read-Host "Validate installation when complete? (y/n, default: y)").ToLower() -ne 'n'
  $Config.CreateBackup = (Read-Host "Create backup of current environment? (y/n, default: y)").ToLower() -ne 'n'

  # Confirm choices
  Write-Host "`nCONFIGURATION SUMMARY:" -ForegroundColor Green
  Write-Host "Selected Unreal Engine version(s): $($selectedVersions -join ', ')"
  Write-Host "Install Visual Studio: $($Config.InstallVisualStudio)"
  Write-Host "Install Epic Games Launcher: $($Config.InstallEpicGamesLauncher)"
  Write-Host "Install development tools: $($Config.InstallDevTools)"
  Write-Host "Install artist tools: $($Config.InstallArtistTools)"
  if ($Config.InstallArtistTools) {
    Write-Host "  - Install texture/material tools: $($Config.InstallTextureTools)"
    Write-Host "  - Install 3D modeling tools: $($Config.Install3DModeling)"
  }
  Write-Host "Configure Git: $($Config.SetupGitConfiguration)"
  Write-Host "Create directories: $($Config.CreateDirectories)"
  Write-Host "Setup PowerShell profile: $($Config.SetupPowershellProfile)"
  Write-Host "Validate installation: $($Config.ValidateInstallation)"
  Write-Host "Create backup: $($Config.CreateBackup)"

  $confirmation = Read-Host "`nProceed with installation? (y/n)"

  if ($confirmation.ToLower() -ne 'y') {
    Write-ColorOutput "Installation cancelled by user" 'Red'
    exit
  }

  return $Config
}

# Function to create a backup of the current environment
function Backup-Environment {
  param (
    [string]$BackupPath
  )

  if (-not (Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
  }

  Write-ColorOutput "Creating environment backup..." 'Yellow'

  # Backup PATH variables
  $machinePathBackup = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
  $userPathBackup = [System.Environment]::GetEnvironmentVariable('Path', 'User')

  $backupInfo = @{
    Timestamp            = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    MachinePath          = $machinePathBackup
    UserPath             = $userPathBackup
    PowerShellProfile    = if (Test-Path $PROFILE) { Get-Content $PROFILE -Raw } else { $null }
    EnvironmentVariables = @{}
  }

  # Backup all environment variables
  [System.Environment]::GetEnvironmentVariables('Machine').GetEnumerator() | ForEach-Object {
    $backupInfo.EnvironmentVariables[$_.Key] = $_.Value
  }

  # Save backup to JSON file
  $backupFile = Join-Path $BackupPath "EnvBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
  $backupInfo | ConvertTo-Json -Depth 4 | Out-File $backupFile -Encoding UTF8

  Write-ColorOutput "Environment backup created at: $backupFile" 'Green'
}

# Function to restore from backup
function Restore-Environment {
  param (
    [string]$BackupPath
  )

  if (-not (Test-Path $BackupPath)) {
    Write-ColorOutput "No backup directory found at: $BackupPath" 'Red'
    return $false
  }

  $backupFiles = Get-ChildItem $BackupPath -Filter "EnvBackup_*.json" | Sort-Object LastWriteTime -Descending

  if ($backupFiles.Count -eq 0) {
    Write-ColorOutput "No backup files found in: $BackupPath" 'Red'
    return $false
  }

  Write-ColorOutput "Available backups:" 'Cyan'
  for ($i = 0; $i -lt [Math]::Min(5, $backupFiles.Count); $i++) {
    Write-ColorOutput "  $($i+1). $($backupFiles[$i].Name) ($(Get-Date $backupFiles[$i].LastWriteTime -Format 'yyyy-MM-dd HH:mm:ss'))" 'White'
  }

  $selection = Read-Host "Select backup to restore (1-$([Math]::Min(5, $backupFiles.Count))), or 'c' to cancel"

  if ($selection -eq 'c') {
    Write-ColorOutput "Restore cancelled" 'Yellow'
    return $false
  }

  $selectedIndex = [int]$selection - 1

  if ($selectedIndex -ge 0 -and $selectedIndex -lt $backupFiles.Count) {
    $selectedBackup = $backupFiles[$selectedIndex]
    $backupData = Get-Content $selectedBackup.FullName -Raw | ConvertFrom-Json

    # Restore PATH variables
    [System.Environment]::SetEnvironmentVariable('Path', $backupData.MachinePath, 'Machine')
    [System.Environment]::SetEnvironmentVariable('Path', $backupData.UserPath, 'User')

    # Restore PowerShell profile
    if ($backupData.PowerShellProfile) {
      $backupData.PowerShellProfile | Out-File $PROFILE -Force -Encoding UTF8
    }

    # Restore environment variables
    $backupData.EnvironmentVariables.PSObject.Properties | ForEach-Object {
      [System.Environment]::SetEnvironmentVariable($_.Name, $_.Value, 'Machine')
    }

    Write-ColorOutput "Environment restored from: $($selectedBackup.Name)" 'Green'
    return $true
  }
  else {
    Write-ColorOutput "Invalid selection" 'Red'
    return $false
  }
}

# Function to check/install Chocolatey
function Ensure-Chocolatey {
  if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-ColorOutput "Installing Chocolatey package manager..." 'Yellow'
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Refresh environment variables after installation
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-ColorOutput "Chocolatey installed successfully!" 'Green'
  }
  else {
    Write-ColorOutput "Chocolatey is already installed, checking for updates..." 'Green'
    choco upgrade chocolatey -y
  }
}

# Function to test if a tool is installed and get its version
function Test-ToolVersion {
  param (
    [string]$Command,
    [string]$VersionArg = '--version',
    [switch]$Silent
  )
  try {
    $output = & $Command $VersionArg 2>&1
    if ($output -is [System.Management.Automation.ErrorRecord]) {
      throw $output
    }

    # Extract version string (handles different formats)
    $versionPattern = '(\d+\.\d+\.?\d*)'
    if ($output -match $versionPattern) {
      $version = $matches[1]
    }
    else {
      $version = $output
    }

    if (-not $Silent) {
      Write-ColorOutput "$Command version: $version" 'Gray'
    }
    return @{ Installed = $true; Version = $version }
  }
  catch {
    if (-not $Silent) {
      Write-ColorOutput "$Command not found or error running version check" 'DarkYellow'
    }
    return @{ Installed = $false; Error = $_ }
  }
}

# Function to add to PATH without duplicates
function Add-ToPath {
  param (
    [string]$PathToAdd,
    [ValidateSet('User', 'Machine')]$Scope,
    [switch]$CreateIfNotExists,
    [switch]$Force
  )

  if ($CreateIfNotExists -and -not (Test-Path $PathToAdd)) {
    New-Item -ItemType Directory -Path $PathToAdd -Force | Out-Null
    Write-ColorOutput "Created directory for PATH: $PathToAdd" 'Yellow'
  }

  if (-not (Test-Path $PathToAdd)) {
    Write-ColorOutput "Warning: Path $PathToAdd does not exist and won't be added to PATH" 'Yellow'
    return $false
  }

  $currentPath = [System.Environment]::GetEnvironmentVariable('Path', $Scope)
  $pathsArray = $currentPath -split ';' | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.TrimEnd('\') }

  if ($pathsArray -notcontains $PathToAdd.TrimEnd('\') -or $Force) {
    if ($Force -and $pathsArray -contains $PathToAdd.TrimEnd('\')) {
      $pathsArray = $pathsArray | Where-Object { $_ -ne $PathToAdd.TrimEnd('\') }
    }

    $newPath = ($pathsArray + $PathToAdd.TrimEnd('\')) -join ';'
    [System.Environment]::SetEnvironmentVariable('Path', $newPath, $Scope)

    # Update current session
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
    [System.Environment]::GetEnvironmentVariable('Path', 'User')
    Write-ColorOutput "Added to $Scope PATH: $PathToAdd" 'Green'
    return $true
  }
  else {
    Write-ColorOutput "Path already exists in $Scope PATH: $PathToAdd" 'DarkGreen'
    return $false
  }
}

# Function to check if path exists in PATH
function Test-PathExists {
  param (
    [string]$PathToCheck,
    [ValidateSet('User', 'Machine')]$Scope
  )

  $currentPath = [System.Environment]::GetEnvironmentVariable('Path', $Scope)
  $pathsArray = $currentPath -split ';' | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.TrimEnd('\') }

  return $pathsArray -contains $PathToCheck.TrimEnd('\')
}

# Function to install Chocolatey packages with progress tracking and compatibility checks
function Install-ChocolateyPackages {
  param (
    [string[]]$Packages,
    [string]$Message,
    [switch]$IgnoreFailures,
    [string]$UnrealVersion = $null
  )

  Write-ColorOutput $Message 'Cyan'
  $totalPackages = $Packages.Count
  $currentPackage = 0
  $results = @()

  foreach ($package in $Packages) {
    $currentPackage++

    # Check if we should substitute a specific version for compatibility
    if ($UnrealVersion -and $compatibilityDB[$UnrealVersion]) {
      $compatDB = $compatibilityDB[$UnrealVersion]

      # Try to find package substitutions
      if ($package -like "visualstudio*community" -and $compatDB.VisualStudio) {
        $package = $compatDB.VisualStudio
      }
      elseif ($package -like "visualstudio*-workload-*" -and $compatDB.VSWorkloads) {
        $matchingWorkload = $compatDB.VSWorkloads | Where-Object { $_ -like "*$($package.Split('-')[-1])" } | Select-Object -First 1
        if ($matchingWorkload) {
          $package = $matchingWorkload
        }
      }
      elseif ($package -like "dotnet-*-sdk" -and $compatDB.DotNetVersions) {
        $matchingDotnet = $compatDB.DotNetVersions | Where-Object { $_ -like "dotnet-*-sdk" } | Select-Object -First 1
        if ($matchingDotnet) {
          $package = $matchingDotnet
        }
      }
      elseif ($package -like "vcredist*" -and $compatDB.VCRedist) {
        $package = $compatDB.VCRedist
      }
    }

    Write-ColorOutput "[$currentPackage/$totalPackages] Installing $package..." 'Yellow' -NoNewLine

    try {
      $output = & choco install $package -y 2>&1
      Write-Host " Done!" -ForegroundColor Green
      $results += [PSCustomObject]@{
        Package = $package
        Success = $true
        Output  = $output
      }
    }
    catch {
      if ($IgnoreFailures) {
        Write-Host " Failed (ignoring)" -ForegroundColor Red
      }
      else {
        Write-Host " Failed!" -ForegroundColor Red
        Write-ColorOutput "Error installing $package. Error: $_" 'Red'
      }
      $results += [PSCustomObject]@{
        Package = $package
        Success = $false
        Error   = $_
      }
    }
  }

  return $results
}

# Function to install Python packages with error handling
function Install-PythonPackages {
  param (
    [string[]]$Packages,
    [string]$Message,
    [string]$PipExecutable = "pip",
    [switch]$Upgrade
  )

  Write-ColorOutput $Message 'Cyan'
  $results = @()

  foreach ($package in $Packages) {
    Write-ColorOutput "Installing Python package: $package..." 'Yellow' -NoNewLine

    try {
      $upgradeArg = if ($Upgrade) { "--upgrade" } else { "" }
      $output = & $PipExecutable install $package $upgradeArg 2>&1
      Write-Host " Done!" -ForegroundColor Green
      $results += [PSCustomObject]@{
        Package = $package
        Success = $true
        Output  = $output
      }
    }
    catch {
      Write-Host " Failed!" -ForegroundColor Red
      Write-ColorOutput "Error installing $package. Error: $_" 'Red'
      $results += [PSCustomObject]@{
        Package = $package
        Success = $false
        Error   = $_
      }
    }
  }

  return $results
}

# Function to verify if a specific Unreal Engine installation exists
function Test-UnrealEngineInstallation {
  param (
    [string]$Version
  )

  $ueDir = Join-Path $env:ProgramFiles "Epic Games\UE_$Version"

  if (Test-Path $ueDir) {
    # Check for the editor executable
    $editorExe = Join-Path $ueDir "Engine\Binaries\Win64\UnrealEditor.exe"
    $legacyEditorExe = Join-Path $ueDir "Engine\Binaries\Win64\UE4Editor.exe"

    if (Test-Path $editorExe) {
      return @{ Installed = $true; Path = $ueDir; EditorExe = $editorExe }
    }
    elseif (Test-Path $legacyEditorExe) {
      return @{ Installed = $true; Path = $ueDir; EditorExe = $legacyEditorExe }
    }
    else {
      return @{ Installed = $false; Path = $ueDir; Reason = "Editor executable not found" }
    }
  }

  return @{ Installed = $false; Reason = "Installation directory not found" }
}

# Function to validate environment for Unreal Engine
function Test-UnrealEnvironment {
  param (
    [string]$UnrealVersion
  )

  $results = @{
    UnrealVersion = $UnrealVersion
    Engine        = Test-UnrealEngineInstallation -Version $UnrealVersion
    RequiredTools = @{}
    Paths         = @{}
    EnvVars       = @{}
  }

  # Check required tools
  $requiredTools = @(
    @{Name = 'git'; Arg = '--version'; Description = 'Git version control' },
    @{Name = 'code'; Arg = '--version'; Description = 'Visual Studio Code' },
    @{Name = 'python'; Arg = '--version'; Description = 'Python programming language' }
  )

  foreach ($tool in $requiredTools) {
    $results.RequiredTools[$tool.Name] = Test-ToolVersion -Command $tool.Name -VersionArg $tool.Arg -Silent
  }

  # Check if Visual Studio is installed
  if ($UnrealVersion -like "4.*") {
    $results.RequiredTools["Visual Studio"] = Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019"
  }
  else {
    $results.RequiredTools["Visual Studio"] = Test-Path "${env:ProgramFiles}\Microsoft Visual Studio\2022"
  }

  # Check paths
  $requiredPaths = @(
    @{ Path = "$env:ProgramFiles\Git\bin"; Scope = 'Machine'; Description = 'Git binaries' },
    @{ Path = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"; Scope = 'User'; Description = 'VS Code' }
  )

  foreach ($pathInfo in $requiredPaths) {
    $results.Paths[$pathInfo.Description] = @{
      Exists = Test-Path $pathInfo.Path
      InPath = Test-PathExists -PathToCheck $pathInfo.Path -Scope $pathInfo.Scope
    }
  }

  # Check environment variables
  $requiredEnvVars = @(
    'UE_ROOT',
    'UE_PROJECTS',
    'UE_ASSETS',
    'UE_PLUGINS'
  )

  foreach ($var in $requiredEnvVars) {
    $value = [System.Environment]::GetEnvironmentVariable($var, 'Machine')
    $results.EnvVars[$var] = @{
      Exists = $null -ne $value
      Value  = $value
    }
  }

  return $results
}

#endregion

#region Installation Components

# Function to install Visual Studio based on Unreal version
function Install-VisualStudio {
  param (
    [string]$UnrealVersion,
    [hashtable]$Config
  )

  if (-not $Config.InstallVisualStudio) {
    Write-ColorOutput "Skipping Visual Studio installation (disabled in config)" 'Yellow'
    return $null
  }

  $results = @{}

  # Determine which Visual Studio version to install based on Unreal Engine version
  if ($UnrealVersion -match "^4\.") {
    $vsPackage = "visualstudio2019community"
    $workloads = @(
      'visualstudio2019-workload-nativedesktop',
      'visualstudio2019-workload-manageddesktop',
      'visualstudio2019-workload-universalplatform',
      'visualstudio2019-workload-nativegame'
    )
  }
  else {
    $vsPackage = "visualstudio2022community"
    $workloads = @(
      'visualstudio2022-workload-nativedesktop',
      'visualstudio2022-workload-manageddesktop',
      'visualstudio2022-workload-universal',
      'visualstudio2022-workload-nativegame'
    )
  }

  # Install VS if not already installed or if forced update
  $vsInstalled = Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\*\*\Common7\IDE\devenv.exe"

  if (-not $vsInstalled) {
    Write-ColorOutput "Installing $vsPackage..." 'Cyan'
    $results["VisualStudio"] = Install-ChocolateyPackages -Packages @($vsPackage) -Message "Installing Visual Studio..." -UnrealVersion $UnrealVersion
  }
  else {
    Write-ColorOutput "Visual Studio is already installed, installing/updating workloads..."
    $results["VisualStudioWorkloads"] = Install-ChocolateyPackages -Packages $workloads -Message "Installing Visual Studio workloads..." -UnrealVersion $UnrealVersion
  }

  return $results
}

# Function to install Epic Games Launcher
function Install-EpicGamesLauncher {
  param (
    [hashtable]$Config
  )

  if (-not $Config.InstallEpicGamesLauncher) {
    Write-ColorOutput "Skipping Epic Games Launcher installation (disabled in config)" 'Yellow'
    return $null
  }

  Write-ColorOutput "Installing Epic Games Launcher..." 'Cyan'
  return Install-ChocolateyPackages -Packages @('epicgameslauncher') -Message "Installing Epic Games Launcher..."
}

# Function to install development tools
function Install-DevTools {
  param (
    [hashtable]$Config
  )

  if (-not $Config.InstallDevTools) {
    Write-ColorOutput "Skipping development tools installation (disabled in config)" 'Yellow'
    return $null
  }

  $devTools = @(
    'git',
    'vscode',
    'docker-desktop',
    'powershell-core',
    'microsoft-windows-terminal',
    'git-lfs',
    'github-desktop',
    'sourcetree',
    'postman',
    'wireshark',
    'ngrok',
    '7zip',
    'winscp',
    'putty',
    'graphviz'
  )

  Write-ColorOutput "Installing development tools..." 'Cyan'
  return Install-ChocolateyPackages -Packages $devTools -Message "Installing development tools..."
}

# Function to install artist tools
function Install-ArtistTools {
  param (
    [hashtable]$Config
  )

  if (-not $Config.InstallArtistTools) {
    Write-ColorOutput "Skipping artist tools installation (disabled in config)" 'Yellow'
    return $null
  }

  $artistTools = @(
    'blender',
    'python',
    'nodejs-lts'
  )

  if ($Config.InstallTextureTools) {
    $artistTools += @(
      'substance-painter',
      'substance-designer',
      'quixel-bridge',
      'photoshop'
    )
  }

  if ($Config.Install3DModeling) {
    $artistTools += @(
      'maya',
      '3dsmax',
      'marmoset-toolbag',
      'zbrush'
    )
  }

  Write-ColorOutput "Installing artist tools..." 'Cyan'
  return Install-ChocolateyPackages -Packages $artistTools -Message "Installing artist tools..."
}

# Function to install Unreal Engine Python dependencies
function Install-UnrealPythonDependencies {
  param (
    [hashtable]$Config
  )

  if (-not $Config.InstallDevTools) {
    Write-ColorOutput "Skipping Unreal Engine Python dependencies installation (disabled in config)" 'Yellow'
    return $null
  }

  $pythonPackages = @(
    'unreal',
    'ue4cli',
    'numpy',
    'opencv-python',
    'pillow',
    'matplotlib',
    'scipy'
  )

  Write-ColorOutput "Installing Unreal Engine Python dependencies..." 'Cyan'
  return Install-PythonPackages -Packages $pythonPackages -Message "Installing Unreal Engine Python dependencies..."
}

# Function to configure Git for Unreal Engine development
function Configure-Git {
  param (
    [hashtable]$Config
  )

  if (-not $Config.SetupGitConfiguration) {
    Write-ColorOutput "Skipping Git configuration (disabled in config)" 'Yellow'
    return $null
  }

  Write-ColorOutput "Configuring Git for Unreal Engine development..." 'Cyan'
  git config --global core.autocrlf true
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global core.fileMode false
  git config --global core.symlinks true
  git config --global core.longpaths true
  git config --global core.ignorecase false
  git config --global core.safecrlf warn
  git config --global credential.helper wincred

  # Configure LFS support
  git lfs install

  Write-ColorOutput "Git configured successfully!" 'Green'
}

# Function to create development directories
function Create-DevelopmentDirectories {
  param (
    [hashtable]$Config
  )

  if (-not $Config.CreateDirectories) {
    Write-ColorOutput "Skipping directory creation (disabled in config)" 'Yellow'
    return $null
  }

  $devFolders = @(
    'Projects',
    'Projects\UnrealProjects',
    'Projects\UnrealPlugins',
    'Projects\UnrealAssets',
    'Workspace',
    'Development',
    'GitHub',
    '.ssh',
    '.config',
    '.docker',
    'Downloads\Development'
  )

  foreach ($folder in $devFolders) {
    $folderPath = Join-Path $env:USERPROFILE $folder
    if (Test-Path $folderPath) {
      Write-ColorOutput "Directory already exists: $folderPath" 'Green'
    }
    else {
      New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
      Write-ColorOutput "Created directory: $folderPath" 'Green'
    }
  }
}

# Function to set environment variables
function Set-EnvironmentVariables {
  param (
    [hashtable]$Config
  )

  Write-ColorOutput "Setting environment variables for Unreal Engine development..." 'Cyan'
  $envVars = @{
    'UE_ROOT'     = Join-Path $env:ProgramFiles "Epic Games"
    'UE_PROJECTS' = Join-Path $env:USERPROFILE "Projects\UnrealProjects"
    'UE_ASSETS'   = Join-Path $env:USERPROFILE "Projects\UnrealAssets"
    'UE_PLUGINS'  = Join-Path $env:USERPROFILE "Projects\UnrealPlugins"
    'PYTHON_HOME' = if (Test-Path "$env:ProgramFiles\Python*") {
                          (Get-ChildItem "$env:ProgramFiles" -Filter "Python*" |
      Where-Object { $_.PSIsContainer } |
      Sort-Object Name -Descending |
      Select-Object -First 1).FullName
    }
    else { Join-Path $env:ProgramFiles "Python" }
  }

  foreach ($var in $envVars.GetEnumerator()) {
    [System.Environment]::SetEnvironmentVariable($var.Key, $var.Value, 'Machine')
    Write-ColorOutput "Set environment variable: $($var.Key) = $($var.Value)" 'Yellow'
  }
}

# Function to create PowerShell profile with Unreal Engine specific aliases
function Create-PowerShellProfile {
  param (
    [hashtable]$Config
  )

  if (-not $Config.SetupPowershellProfile) {
    Write-ColorOutput "Skipping PowerShell profile setup (disabled in config)" 'Yellow'
    return $null
  }

  if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
  }

  $profileContent = @"
# Unreal Engine specific aliases and functions
# Profile generated by UE Setup Script v$SCRIPT_VERSION on $SCRIPT_TIMESTAMP

# Navigation functions for Unreal Engine
function Get-UnrealEngineVersions {
    Get-ChildItem (Join-Path `$env:ProgramFiles "Epic Games") -Filter "UE_*" |
    Where-Object { `$_.PSIsContainer } |
    Sort-Object Name
}

function ue4 { Set-Location (Join-Path `$env:UE_ROOT 'UE_4.27') }
function ue5 { Set-Location (Join-Path `$env:UE_ROOT 'UE_5.0') }
function ue {
    `$versions = Get-UnrealEngineVersions
    if (-not `$versions) {
        Write-Host "No Unreal Engine installations found" -ForegroundColor Red
        return
    }
    `$latest = `$versions | Select-Object -Last 1
    Set-Location `$latest.FullName
    Write-Host "Navigated to `$(`$latest.Name)" -ForegroundColor Green
}

# Project navigation
function ueprojects { Set-Location `$env:UE_PROJECTS }
function ueassets { Set-Location `$env:UE_ASSETS }
function ueplugins { Set-Location `$env:UE_PLUGINS }

# Quick navigation shortcuts
function cdp { Set-Location (Join-Path `$env:USERPROFILE 'Projects') }
function cdw { Set-Location (Join-Path `$env:USERPROFILE 'Workspace') }
function cdg { Set-Location (Join-Path `$env:USERPROFILE 'GitHub') }

# Git shortcuts
function gs { git status }
function gp { git pull }
function gps { git push }
function gc { git checkout }
function gb { git branch }
function gl { git log --oneline --graph --decorate -10 }

# Function to create a new Unreal Engine project (requires UE installed)
function New-UEProject {
    param(
        [Parameter(Mandatory=`$true)]
        [string]`$ProjectName,

        [Parameter(Mandatory=`$false)]
        [string]`$EngineVersion = "5.0",

        [Parameter(Mandatory=`$false)]
        [string]`$TemplateName = "TP_Blank",

        [Parameter(Mandatory=`$false)]
        [string]`$OutputPath = `$env:UE_PROJECTS
    )

    `$enginePath = Join-Path `$env:UE_ROOT "UE_`$EngineVersion"
    if (-not (Test-Path `$enginePath)) {
        Write-Host "Engine version UE_`$EngineVersion not found!" -ForegroundColor Red
        return
    }

    `$fullOutputPath = Join-Path `$OutputPath `$ProjectName
    `$engineExe = Join-Path `$enginePath "Engine\Binaries\Win64\UnrealEditor.exe"
    if (-not (Test-Path `$engineExe)) {
        `$engineExe = Join-Path `$enginePath "Engine\Binaries\Win64\UE4Editor.exe"
    }

    if (-not (Test-Path `$engineExe)) {
        Write-Host "Could not find Unreal Editor executable!" -ForegroundColor Red
        return
    }

    & `$engineExe -createproject -projectname="`$ProjectName" -templatename="`$TemplateName" -projectpath="`$OutputPath"

    if (Test-Path `$fullOutputPath) {
        Write-Host "Project created successfully at: `$fullOutputPath" -ForegroundColor Green
    } else {
        Write-Host "Failed to create project!" -ForegroundColor Red
    }
}
"@

  Add-Content $PROFILE $profileContent
  Write-ColorOutput "PowerShell profile configured with Unreal Engine aliases and functions!" 'Green'
}

# Function to validate the installation
function Validate-Installation {
  param (
    [hashtable]$Config
  )

  if (-not $Config.ValidateInstallation) {
    Write-ColorOutput "Skipping installation validation (disabled in config)" 'Yellow'
    return $null
  }

  Write-ColorOutput "`nPerforming final validation..." 'Cyan'
  $validationResults = @()

  $toolsToValidate = @(
    @{Name = 'git'; Arg = '--version'; Description = 'Git version control' },
    @{Name = 'code'; Arg = '--version'; Description = 'Visual Studio Code' },
    @{Name = 'python'; Arg = '--version'; Description = 'Python programming language' },
    @{Name = 'node'; Arg = '--version'; Description = 'Node.js runtime' },
    @{Name = 'cmake'; Arg = '--version'; Description = 'CMake build system' },
    @{Name = 'docker'; Arg = '--version'; Description = 'Docker container platform' }
  )

  foreach ($tool in $toolsToValidate) {
    if (Test-ToolVersion -Command $tool.Name -VersionArg $tool.Arg -Silent) {
      $validationResults += "$($tool.Name): OK ($($tool.Description))"
    }
    else {
      $validationResults += "$($tool.Name): Not found or not working ($($tool.Description))"
    }
  }

  # Output final summary
  Write-ColorOutput "`n╔═══════════════════════════════════════╗" 'Cyan'
  Write-ColorOutput "║ Installation Summary                  ║" 'Cyan'
  Write-ColorOutput "╚═══════════════════════════════════════╝" 'Cyan'
  $validationResults | ForEach-Object { Write-ColorOutput $_ 'White' }

  # Check for Unreal Engine installations
  $unrealInstalls = Get-ChildItem (Join-Path $env:ProgramFiles "Epic Games") -Filter "UE_*" -ErrorAction SilentlyContinue |
  Where-Object { $_.PSIsContainer } |
  Sort-Object Name

  Write-ColorOutput "`nUnreal Engine Installations:" 'Cyan'
  if ($unrealInstalls) {
    $unrealInstalls | ForEach-Object { Write-ColorOutput "- $($_.Name)" 'White' }
  }
  else {
    Write-ColorOutput "- No Unreal Engine installations found. Please use Epic Games Launcher to install Unreal Engine." 'Yellow'
  }

  # Display environment variables
  Write-ColorOutput "`nEnvironment Variables:" 'Cyan'
  foreach ($var in $envVars.GetEnumerator()) {
    Write-ColorOutput "- $($var.Key) = $($var.Value)" 'White'
  }

  # Final instructions
  Write-ColorOutput "`n╔═══════════════════════════════════════╗" 'Cyan'
  Write-ColorOutput "║ Setup Complete                        ║" 'Cyan'
  Write-ColorOutput "╚═══════════════════════════════════════╝" 'Cyan'
  Write-ColorOutput "Unreal Engine Development Environment has been set up successfully!" 'Green'
  Write-ColorOutput "Next steps:" 'White'
  Write-ColorOutput "1. Use Epic Games Launcher to install Unreal Engine (if not already installed)" 'White'
  Write-ColorOutput "2. Open a new PowerShell window to use the configured aliases and functions" 'White'
  Write-ColorOutput "3. Use 'New-UEProject' function to create new Unreal Engine projects" 'White'
  Write-ColorOutput "4. Check your Unreal Engine installation path at $env:UE_ROOT" 'White'

  Write-ColorOutput "`nThank you for using the Unreal Engine Development Environment Setup Script!" 'Green'
}

#endregion

# Main script execution
function Main {
  # Start logging
  Start-Logging

  # Show welcome banner
  Show-WelcomeBanner

  # Ensure Chocolatey is installed
  Ensure-Chocolatey

  # Get user choices
  $config = Get-UserChoices -Config $defaultConfig

  # Create backup if configured
  if ($config.CreateBackup) {
    Backup-Environment -BackupPath $config.BackupPath
  }

  # Install Visual Studio
  foreach ($version in $config.SelectedUnrealVersions) {
    Install-VisualStudio -UnrealVersion $version -Config $config
  }

  # Install Epic Games Launcher
  Install-EpicGamesLauncher -Config $config

  # Install development tools
  Install-DevTools -Config $config

  # Install artist tools
  Install-ArtistTools -Config $config

  # Install Unreal Engine Python dependencies
  Install-UnrealPythonDependencies -Config $config

  # Configure Git
  Configure-Git -Config $config

  # Create development directories
  Create-DevelopmentDirectories -Config $config

  # Set environment variables
  Set-EnvironmentVariables -Config $config

  # Create PowerShell profile
  Create-PowerShellProfile -Config $config

  # Validate installation
  Validate-Installation -Config $config
}

# Execute the main function
Main
