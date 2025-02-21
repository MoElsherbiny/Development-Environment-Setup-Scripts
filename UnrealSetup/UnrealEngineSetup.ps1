# Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script version and timestamp
$SCRIPT_VERSION = "5.1.0"
$SCRIPT_TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

#region Configuration

# Default configuration
$defaultConfig = @{
  PromptForChoices         = $true
  ValidateInstallation     = $true
  CreateBackup             = $true
  ParallelInstall          = $true
  InstallVisualStudio      = $true
  InstallEpicGamesLauncher = $true
  InstallArtistTools       = $true
  InstallDevTools          = $true
  InstallTextureTools      = $true
  Install3DModeling        = $true
  InstallUnrealExtras      = $true
  UnrealEngineVersions     = @("4.27", "5.0", "5.1", "5.2", "5.3", "5.4")
  DefaultUnrealVersion     = "5.4"
  SetupGitConfiguration    = $true
  CreateDirectories        = $true
  SetupPowershellProfile   = $true
  BackupPath               = (Join-Path $env:USERPROFILE "UnrealSetupBackup")
  LogPath                  = (Join-Path $env:TEMP "UnrealEngineSetup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log")
}

# Compatibility database for tool versions based on Unreal Engine version
$compatibilityDB = @{
  "4.27" = @{ VisualStudio = "visualstudio2019community"; VSWorkloads = @('visualstudio2019-workload-nativedesktop', 'visualstudio2019-workload-manageddesktop', 'visualstudio2019-workload-universalplatform', 'visualstudio2019-workload-nativegame'); DotNetVersions = @('dotnet-sdk', 'dotnet-5.0-sdk'); VCRedist = 'vcredist140' }
  "5.0"  = @{ VisualStudio = "visualstudio2022community"; VSWorkloads = @('visualstudio2022-workload-nativedesktop', 'visualstudio2022-workload-manageddesktop', 'visualstudio2022-workload-universal', 'visualstudio2022-workload-nativegame'); DotNetVersions = @('dotnet-6.0-sdk', 'dotnet-5.0-sdk'); VCRedist = 'vcredist-all' }
  "5.1"  = @{ VisualStudio = "visualstudio2022community"; VSWorkloads = @('visualstudio2022-workload-nativedesktop', 'visualstudio2022-workload-manageddesktop', 'visualstudio2022-workload-universal', 'visualstudio2022-workload-nativegame'); DotNetVersions = @('dotnet-6.0-sdk', 'dotnet-5.0-sdk'); VCRedist = 'vcredist-all' }
  "5.2"  = @{ VisualStudio = "visualstudio2022community"; VSWorkloads = @('visualstudio2022-workload-nativedesktop', 'visualstudio2022-workload-manageddesktop', 'visualstudio2022-workload-universal', 'visualstudio2022-workload-nativegame'); DotNetVersions = @('dotnet-7.0-sdk', 'dotnet-6.0-sdk'); VCRedist = 'vcredist-all' }
  "5.3"  = @{ VisualStudio = "visualstudio2022community"; VSWorkloads = @('visualstudio2022-workload-nativedesktop', 'visualstudio2022-workload-manageddesktop', 'visualstudio2022-workload-universal', 'visualstudio2022-workload-nativegame'); DotNetVersions = @('dotnet-8.0-sdk', 'dotnet-7.0-sdk'); VCRedist = 'vcredist-all' }
  "5.4"  = @{ VisualStudio = "visualstudio2022community"; VSWorkloads = @('visualstudio2022-workload-nativedesktop', 'visualstudio2022-workload-manageddesktop', 'visualstudio2022-workload-universal', 'visualstudio2022-workload-nativegame'); DotNetVersions = @('dotnet-8.0-sdk', 'dotnet-7.0-sdk'); VCRedist = 'vcredist-all' }
}

#endregion

#region Utility Functions

function Start-Logging {
  $script:LogFile = $defaultConfig.LogPath
  try {
    Start-Transcript -Path $LogFile -Append -ErrorAction Stop
    Write-Host "Logging to: $LogFile"
  }
  catch {
    Write-Host "Failed to start logging: $_" -ForegroundColor Red
    exit 1
  }
}

function Write-ColorOutput {
  param(
    [string]$Message,
    [string]$Color = 'White',
    [switch]$NoNewLine,
    [switch]$LogOnly
  )
  $timestamp = Get-Date -Format "HH:mm:ss"
  $output = "[$timestamp] $Message"
  try {
    $output | Out-File -FilePath $script:LogFile -Append -Encoding UTF8 -ErrorAction Stop
  }
  catch {
    Write-Host "Warning: Failed to write to log: $_" -ForegroundColor Yellow
  }
  if (-not $LogOnly) {
    if ($NoNewLine) {
      Write-Host $output -ForegroundColor $Color -NoNewline
    }
    else {
      Write-Host $output -ForegroundColor $Color
    }
  }
}

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
  Write-Host "This script sets up an optimized Unreal Engine environment for artists and developers."
  Write-Host "Features enhanced tools, workflows, and validation as of February 2025."
  Write-Host ("=" * $width) -ForegroundColor DarkGray
}

function Get-UserChoices {
  param ([hashtable]$Config)
  if (-not $Config.PromptForChoices) { return $Config }
  Write-Host "`nCONFIGURATION OPTIONS" -ForegroundColor Cyan
  Write-Host "===================="
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
    $versionInput = Read-Host "Select Unreal Engine version(s) by number (comma-separated, or 'all', default: $($Config.DefaultUnrealVersion))"
    if ([string]::IsNullOrEmpty($versionInput)) { $selectedVersions.Add($Config.DefaultUnrealVersion); break }
    if ($versionInput -eq 'all') { $selectedVersions = $Config.UnrealEngineVersions; break }
    $selectedIndices = $versionInput -split ',' | ForEach-Object { [int]$_.Trim() - 1 }
    foreach ($index in $selectedIndices) {
      if ($index -ge 0 -and $index -lt $versionChoices.Count) { [void]$selectedVersions.Add($versionChoices[$index]) }
    }
  } while ($selectedVersions.Count -eq 0)
  $Config.SelectedUnrealVersions = $selectedVersions
  Write-Host "`n2. Select Software to Install" -ForegroundColor Yellow
  $Config.InstallVisualStudio = (Read-Host "Install Visual Studio? (y/n, default: y)").ToLower() -ne 'n'
  $Config.InstallEpicGamesLauncher = (Read-Host "Install Epic Games Launcher? (y/n, default: y)").ToLower() -ne 'n'
  $Config.InstallDevTools = (Read-Host "Install development tools (Git, VSCode, etc.)? (y/n, default: y)").ToLower() -ne 'n'
  $Config.InstallUnrealExtras = (Read-Host "Install Unreal-specific tools (UE4CLI, etc.)? (y/n, default: y)").ToLower() -ne 'n'
  $Config.InstallArtistTools = (Read-Host "Install artist tools? (y/n, default: y)").ToLower() -ne 'n'
  if ($Config.InstallArtistTools) {
    $Config.InstallTextureTools = (Read-Host "Install texture/material tools (Substance, Quixel, etc.)? (y/n, default: y)").ToLower() -ne 'n'
    $Config.Install3DModeling = (Read-Host "Install 3D modeling tools (Blender, Maya, etc.)? (y/n, default: y)").ToLower() -ne 'n'
  }
  Write-Host "`n3. Environment Setup" -ForegroundColor Yellow
  $Config.SetupGitConfiguration = (Read-Host "Configure Git for Unreal Engine? (y/n, default: y)").ToLower() -ne 'n'
  $Config.CreateDirectories = (Read-Host "Create recommended directory structure? (y/n, default: y)").ToLower() -ne 'n'
  $Config.SetupPowershellProfile = (Read-Host "Setup PowerShell profile with Unreal shortcuts? (y/n, default: y)").ToLower() -ne 'n'
  $Config.ValidateInstallation = (Read-Host "Validate installation when complete? (y/n, default: y)").ToLower() -ne 'n'
  $Config.CreateBackup = (Read-Host "Create backup of current environment? (y/n, default: y)").ToLower() -ne 'n'
  $Config.ParallelInstall = (Read-Host "Use parallel installation for faster setup? (y/n, default: y)").ToLower() -ne 'n'
  Write-Host "`nCONFIGURATION SUMMARY:" -ForegroundColor Green
  Write-Host "Selected Unreal Engine version(s): $($selectedVersions -join ', ')"
  Write-Host "Install Visual Studio: $($Config.InstallVisualStudio)"
  Write-Host "Install Epic Games Launcher: $($Config.InstallEpicGamesLauncher)"
  Write-Host "Install development tools: $($Config.InstallDevTools)"
  Write-Host "Install Unreal extras: $($Config.InstallUnrealExtras)"
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
  Write-Host "Parallel installation: $($Config.ParallelInstall)"
  $confirmation = Read-Host "`nProceed with installation? (y/n)"
  if ($confirmation.ToLower() -ne 'y') {
    Write-ColorOutput "Installation cancelled by user" 'Red'
    exit
  }
  return $Config
}

function Backup-Environment {
  param ([string]$BackupPath)
  if (-not (Test-Path $BackupPath)) { New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null }
  Write-ColorOutput "Creating environment backup..." 'Yellow'
  $machinePathBackup = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
  $userPathBackup = [System.Environment]::GetEnvironmentVariable('Path', 'User')
  $backupInfo = @{ Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; MachinePath = $machinePathBackup; UserPath = $userPathBackup; PowerShellProfile = if (Test-Path $PROFILE) { Get-Content $PROFILE -Raw } else { $null }; EnvironmentVariables = @{} }
  [System.Environment]::GetEnvironmentVariables('Machine').GetEnumerator() | ForEach-Object { $backupInfo.EnvironmentVariables[$_.Key] = $_.Value }
  $backupFile = Join-Path $BackupPath "EnvBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
  $backupInfo | ConvertTo-Json -Depth 4 | Out-File $backupFile -Encoding UTF8
  Write-ColorOutput "Environment backup created at: $backupFile" 'Green'
}

function Restore-Environment {
  param ([string]$BackupPath)
  if (-not (Test-Path $BackupPath)) { Write-ColorOutput "No backup directory found at: $BackupPath" 'Red'; return $false }
  $backupFiles = Get-ChildItem $BackupPath -Filter "EnvBackup_*.json" | Sort-Object LastWriteTime -Descending
  if ($backupFiles.Count -eq 0) { Write-ColorOutput "No backup files found in: $BackupPath" 'Red'; return $false }
  Write-ColorOutput "Available backups:" 'Cyan'
  for ($i = 0; $i -lt [Math]::Min(5, $backupFiles.Count); $i++) { Write-ColorOutput "  $($i+1). $($backupFiles[$i].Name) ($(Get-Date $backupFiles[$i].LastWriteTime -Format 'yyyy-MM-dd HH:mm:ss'))" 'White' }
  $selection = Read-Host "Select backup to restore (1-$([Math]::Min(5, $backupFiles.Count))), or 'c' to cancel"
  if ($selection -eq 'c') { Write-ColorOutput "Restore cancelled" 'Yellow'; return $false }
  $selectedIndex = [int]$selection - 1
  if ($selectedIndex -ge 0 -and $selectedIndex -lt $backupFiles.Count) {
    $selectedBackup = $backupFiles[$selectedIndex]
    $backupData = Get-Content $selectedBackup.FullName -Raw | ConvertFrom-Json
    [System.Environment]::SetEnvironmentVariable('Path', $backupData.MachinePath, 'Machine')
    [System.Environment]::SetEnvironmentVariable('Path', $backupData.UserPath, 'User')
    if ($backupData.PowerShellProfile) { $backupData.PowerShellProfile | Out-File $PROFILE -Force -Encoding UTF8 }
    $backupData.EnvironmentVariables.PSObject.Properties | ForEach-Object { [System.Environment]::SetEnvironmentVariable($_.Name, $_.Value, 'Machine') }
    Write-ColorOutput "Environment restored from: $($selectedBackup.Name)" 'Green'
    return $true
  }
  else {
    Write-ColorOutput "Invalid selection" 'Red'
    return $false
  }
}

function Test-AndInstallChocolatey {
  if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-ColorOutput "Installing Chocolatey package manager..." 'Yellow'
    try {
      Set-ExecutionPolicy Bypass -Scope Process -Force
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
      Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
      $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
      Write-ColorOutput "Chocolatey installed successfully!" 'Green'
    }
    catch {
      Write-ColorOutput "Failed to install Chocolatey: $_" 'Red'
      exit 1
    }
  }
  else {
    Write-ColorOutput "Chocolatey is already installed, checking for updates..." 'Green'
    choco upgrade chocolatey -y
  }
}

function Test-ToolVersion {
  param ([string]$Command, [string]$VersionArg = '--version', [switch]$Silent)
  try {
    $output = & $Command $VersionArg 2>&1
    if ($output -is [System.Management.Automation.ErrorRecord]) { throw $output }
    $versionPattern = '(\d+\.\d+\.?\d*)'
    if ($output -match $versionPattern) { $version = $matches[1] } else { $version = $output }
    if (-not $Silent) { Write-ColorOutput "$Command version: $version" 'Gray' }
    return @{ Installed = $true; Version = $version }
  }
  catch {
    if (-not $Silent) { Write-ColorOutput "$Command not found or error running version check: $_" 'DarkYellow' }
    return @{ Installed = $false; Error = $_ }
  }
}

function Add-ToPath {
  param ([string]$PathToAdd, [ValidateSet('User', 'Machine')]$Scope, [switch]$CreateIfNotExists, [switch]$Force)
  if ($CreateIfNotExists -and -not (Test-Path $PathToAdd)) { New-Item -ItemType Directory -Path $PathToAdd -Force | Out-Null; Write-ColorOutput "Created directory for PATH: $PathToAdd" 'Yellow' }
  if (-not (Test-Path $PathToAdd)) { Write-ColorOutput "Warning: Path $PathToAdd does not exist and won't be added to PATH" 'Yellow'; return $false }
  $currentPath = [System.Environment]::GetEnvironmentVariable('Path', $Scope)
  $pathsArray = $currentPath -split ';' | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.TrimEnd('\') }
  if ($pathsArray -notcontains $PathToAdd.TrimEnd('\') -or $Force) {
    if ($Force -and $pathsArray -contains $PathToAdd.TrimEnd('\')) { $pathsArray = $pathsArray | Where-Object { $_ -ne $PathToAdd.TrimEnd('\') } }
    $newPath = ($pathsArray + $PathToAdd.TrimEnd('\')) -join ';'
    [System.Environment]::SetEnvironmentVariable('Path', $newPath, $Scope)
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
    Write-ColorOutput "Added to $Scope PATH: $PathToAdd" 'Green'
    return $true
  }
  else {
    Write-ColorOutput "Path already exists in $Scope PATH: $PathToAdd" 'DarkGreen'
    return $false
  }
}

function Test-PathExists {
  param ([string]$PathToCheck, [ValidateSet('User', 'Machine')]$Scope)
  $currentPath = [System.Environment]::GetEnvironmentVariable('Path', $Scope)
  $pathsArray = $currentPath -split ';' | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.TrimEnd('\') }
  return $pathsArray -contains $PathToCheck.TrimEnd('\')
}

function Install-ChocolateyPackages {
  param (
    [string[]]$Packages,
    [string]$Message,
    [switch]$IgnoreFailures,
    [string]$UnrealVersion = $null,
    [switch]$Parallel
  )

  Write-ColorOutput $Message 'Cyan'
  $totalPackages = $Packages.Count
  $currentPackage = 0
  $results = @()

  if ($Parallel) {
    $jobs = $Packages | ForEach-Object {
      $package = $_
      if ($UnrealVersion -and $compatibilityDB[$UnrealVersion]) {
        $compatDB = $compatibilityDB[$UnrealVersion]
        if ($package -like "visualstudio*community") { $package = $compatDB.VisualStudio }
        elseif ($package -like "visualstudio*-workload-*") {
          $matchingWorkload = $compatDB.VSWorkloads | Where-Object { $_ -like "*$($package.Split('-')[-1])" } | Select-Object -First 1
          if ($matchingWorkload) { $package = $matchingWorkload }
        }
        elseif ($package -like "dotnet-*-sdk") {
          $matchingDotnet = $compatDB.DotNetVersions | Where-Object { $_ -like "dotnet-*-sdk" } | Select-Object -First 1
          if ($matchingDotnet) { $package = $matchingDotnet }
        }
        elseif ($package -like "vcredist*") { $package = $compatDB.VCRedist }
      }
      Start-Job -ScriptBlock {
        param($pkg)
        $output = & choco install $pkg -y 2>&1
        [PSCustomObject]@{ Package = $pkg; Success = $?; Output = $output }
      } -ArgumentList $package
    }
    $results = $jobs | ForEach-Object {
      $currentPackage++
      $packageName = $_.ScriptBlock.Module.Parameters.pkg
      Write-ColorOutput "[$currentPackage/$totalPackages] Installing $packageName..." 'Yellow' -NoNewLine
      $result = Receive-Job $_ -Wait -AutoRemoveJob
      if ($result.Success) {
        Write-Host " Done!" -ForegroundColor 'Green'
      }
      else {
        Write-Host " Failed!" -ForegroundColor 'Red'
      }
      $result
    }
  }
  else {
    foreach ($package in $Packages) {
      $currentPackage++
      if ($UnrealVersion -and $compatibilityDB[$UnrealVersion]) {
        $compatDB = $compatibilityDB[$UnrealVersion]
        if ($package -like "visualstudio*community") { $package = $compatDB.VisualStudio }
        elseif ($package -like "visualstudio*-workload-*") {
          $matchingWorkload = $compatDB.VSWorkloads | Where-Object { $_ -like "*$($package.Split('-')[-1])" } | Select-Object -First 1
          if ($matchingWorkload) { $package = $matchingWorkload }
        }
        elseif ($package -like "dotnet-*-sdk") {
          $matchingDotnet = $compatDB.DotNetVersions | Where-Object { $_ -like "dotnet-*-sdk" } | Select-Object -First 1
          if ($matchingDotnet) { $package = $matchingDotnet }
        }
        elseif ($package -like "vcredist*") { $package = $compatDB.VCRedist }
      }
      Write-ColorOutput "[$currentPackage/$totalPackages] Installing $package..." 'Yellow' -NoNewLine
      try {
        $output = & choco install $package -y 2>&1
        Write-Host " Done!" -ForegroundColor Green
        $results += [PSCustomObject]@{ Package = $package; Success = $true; Output = $output }
      }
      catch {
        if ($IgnoreFailures) {
          Write-Host " Failed (ignoring)" -ForegroundColor Red
        }
        else {
          Write-Host " Failed!" -ForegroundColor Red
        }
        Write-ColorOutput "Error installing ${package}: $_" 'Red'
        $results += [PSCustomObject]@{ Package = $package; Success = $false; Error = $_ }
      }
    }
  }
  return $results
}

function Install-PythonPackages {
  param ([string[]]$Packages, [string]$Message, [string]$PipExecutable = "pip", [switch]$Upgrade)
  Write-ColorOutput $Message 'Cyan'
  $results = @()
  foreach ($package in $Packages) {
    Write-ColorOutput "Installing Python package: $package..." 'Yellow' -NoNewLine
    try {
      $upgradeArg = if ($Upgrade) { "--upgrade" } else { "" }
      $output = & $PipExecutable install $package $upgradeArg 2>&1
      Write-Host " Done!" -ForegroundColor Green
      $results += [PSCustomObject]@{ Package = $package; Success = $true; Output = $output }
    }
    catch {
      Write-Host " Failed!" -ForegroundColor Red
      Write-ColorOutput "Error installing ${package}: $_" 'Red'
      $results += [PSCustomObject]@{ Package = $package; Success = $false; Error = $_ }
    }
  }
  return $results
}

function Test-UnrealEngineInstallation {
  param ([string]$Version)
  $ueDir = Join-Path $env:ProgramFiles "Epic Games\UE_$Version"
  if (Test-Path $ueDir) {
    $editorExe = Join-Path $ueDir "Engine\Binaries\Win64\UnrealEditor.exe"
    $legacyEditorExe = Join-Path $ueDir "Engine\Binaries\Win64\UE4Editor.exe"
    if (Test-Path $editorExe) { return @{ Installed = $true; Path = $ueDir; EditorExe = $editorExe } }
    elseif (Test-Path $legacyEditorExe) { return @{ Installed = $true; Path = $ueDir; EditorExe = $legacyEditorExe } }
    else { return @{ Installed = $false; Path = $ueDir; Reason = "Editor executable not found" } }
  }
  return @{ Installed = $false; Reason = "Installation directory not found" }
}

function Test-UnrealEnvironment {
  param ([string]$UnrealVersion)
  $results = @{ UnrealVersion = $UnrealVersion; Engine = Test-UnrealEngineInstallation -Version $UnrealVersion; RequiredTools = @{}; Paths = @{}; EnvVars = @{} }
  $requiredTools = @(@{Name = 'git'; Arg = '--version'; Description = 'Git version control' }, @{Name = 'code'; Arg = '--version'; Description = 'Visual Studio Code' }, @{Name = 'python'; Arg = '--version'; Description = 'Python programming language' })
  foreach ($tool in $requiredTools) { $results.RequiredTools[$tool.Name] = Test-ToolVersion -Command $tool.Name -VersionArg $tool.Arg -Silent }
  if ($UnrealVersion -like "4.*") { $results.RequiredTools["Visual Studio"] = Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019" } else { $results.RequiredTools["Visual Studio"] = Test-Path "${env:ProgramFiles}\Microsoft Visual Studio\2022" }
  $requiredPaths = @(@{ Path = "$env:ProgramFiles\Git\bin"; Scope = 'Machine'; Description = 'Git binaries' }, @{ Path = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"; Scope = 'User'; Description = 'VS Code' })
  foreach ($pathInfo in $requiredPaths) { $results.Paths[$pathInfo.Description] = @{ Exists = Test-Path $pathInfo.Path; InPath = Test-PathExists -PathToCheck $pathInfo.Path -Scope $pathInfo.Scope } }
  $requiredEnvVars = @('UE_ROOT', 'UE_PROJECTS', 'UE_ASSETS', 'UE_PLUGINS')
  foreach ($var in $requiredEnvVars) { $value = [System.Environment]::GetEnvironmentVariable($var, 'Machine'); $results.EnvVars[$var] = @{ Exists = $null -ne $value; Value = $value } }
  return $results
}

#endregion

#region Installation Components

function Install-VisualStudio {
  param ([string]$UnrealVersion, [hashtable]$Config)
  if (-not $Config.InstallVisualStudio) { Write-ColorOutput "Skipping Visual Studio installation (disabled in config)" 'Yellow'; return $null }
  $results = @{}
  if ($UnrealVersion -match "^4\.") {
    $vsPackage = "visualstudio2019community"
    $workloads = @('visualstudio2019-workload-nativedesktop', 'visualstudio2019-workload-manageddesktop', 'visualstudio2019-workload-universalplatform', 'visualstudio2019-workload-nativegame')
  }
  else {
    $vsPackage = "visualstudio2022community"
    $workloads = @('visualstudio2022-workload-nativedesktop', 'visualstudio2022-workload-manageddesktop', 'visualstudio2022-workload-universal', 'visualstudio2022-workload-nativegame')
  }
  $vsInstalled = Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\*\*\Common7\IDE\devenv.exe" -or Test-Path "${env:ProgramFiles}\Microsoft Visual Studio\*\*\Common7\IDE\devenv.exe"
  if (-not $vsInstalled) {
    Write-ColorOutput "Installing $vsPackage..." 'Cyan'
    $results["VisualStudio"] = Install-ChocolateyPackages -Packages @($vsPackage) -Message "Installing Visual Studio..." -UnrealVersion $UnrealVersion -Parallel:$Config.ParallelInstall
  }
  else {
    Write-ColorOutput "Visual Studio is already installed, installing/updating workloads..." 'Green'
  }
  $results["VisualStudioWorkloads"] = Install-ChocolateyPackages -Packages $workloads -Message "Installing Visual Studio workloads..." -UnrealVersion $UnrealVersion -Parallel:$Config.ParallelInstall
  return $results
}

function Install-EpicGamesLauncher {
  param ([hashtable]$Config)
  if (-not $Config.InstallEpicGamesLauncher) { Write-ColorOutput "Skipping Epic Games Launcher installation (disabled in config)" 'Yellow'; return $null }
  Write-ColorOutput "Installing Epic Games Launcher..." 'Cyan'
  return Install-ChocolateyPackages -Packages @('epicgameslauncher') -Message "Installing Epic Games Launcher..." -Parallel:$Config.ParallelInstall
}

function Install-DevTools {
  param ([hashtable]$Config)
  if (-not $Config.InstallDevTools) { Write-ColorOutput "Skipping development tools installation (disabled in config)" 'Yellow'; return $null }
  $devTools = @('git', 'vscode', 'docker-desktop', 'powershell-core', 'microsoft-windows-terminal', 'git-lfs', 'github-desktop', 'sourcetree', 'postman', 'wireshark', 'ngrok', '7zip', 'winscp', 'putty', 'graphviz', 'cmake', 'vcpkg', 'nodejs')
  Write-ColorOutput "Installing development tools..." 'Cyan'
  return Install-ChocolateyPackages -Packages $devTools -Message "Installing development tools..." -Parallel:$Config.ParallelInstall
}

function Install-ArtistTools {
  param ([hashtable]$Config)
  if (-not $Config.InstallArtistTools) { Write-ColorOutput "Skipping artist tools installation (disabled in config)" 'Yellow'; return $null }
  $artistTools = @('blender', 'python', 'nodejs-lts', 'krita', 'gimp', 'houdini')
  if ($Config.InstallTextureTools) { $artistTools += @('adobe-substance-3d-painter', 'adobe-substance-3d-designer', 'quixel-bridge', 'photoshop') }
  if ($Config.Install3DModeling) { $artistTools += @('maya', '3dsmax', 'marmoset-toolbag', 'zbrush', 'cinema4d') }
  Write-ColorOutput "Installing artist tools..." 'Cyan'
  return Install-ChocolateyPackages -Packages $artistTools -Message "Installing artist tools..." -Parallel:$Config.ParallelInstall
}

function Install-UnrealExtras {
  param ([hashtable]$Config)
  if (-not $Config.InstallUnrealExtras) { Write-ColorOutput "Skipping Unreal extras installation (disabled in config)" 'Yellow'; return $null }
  $unrealExtras = @('ue4cli', 'rider', 'dotnet-8.0-sdk')
  Write-ColorOutput "Installing Unreal-specific extras..." 'Cyan'
  return Install-ChocolateyPackages -Packages $unrealExtras -Message "Installing Unreal extras..." -Parallel:$Config.ParallelInstall
}

function Install-UnrealPythonDependencies {
  param ([hashtable]$Config)
  if (-not $Config.InstallDevTools) { Write-ColorOutput "Skipping Unreal Engine Python dependencies installation (disabled in config)" 'Yellow'; return $null }
  $pythonPackages = @('unreal', 'ue4cli', 'numpy', 'opencv-python', 'pillow', 'matplotlib', 'scipy', 'requests', 'psutil', 'pywin32')
  Write-ColorOutput "Installing Unreal Engine Python dependencies..." 'Cyan'
  return Install-PythonPackages -Packages $pythonPackages -Message "Installing Unreal Engine Python dependencies..." -Upgrade
}

function Set-GitConfiguration {
  param ([hashtable]$Config)
  if (-not $Config.SetupGitConfiguration) { Write-ColorOutput "Skipping Git configuration (disabled in config)" 'Yellow'; return $null }
  Write-ColorOutput "Configuring Git for Unreal Engine development..." 'Cyan'
  try {
    git config --global core.autocrlf true
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.fileMode false
    git config --global core.symlinks true
    git config --global core.longpaths true
    git config --global core.ignorecase false
    git config --global core.safecrlf warn
    git config --global credential.helper wincred
    git config --global diff.renames true
    git config --global merge.conflictstyle diff3
    git lfs install
    Write-ColorOutput "Git configured successfully!" 'Green'
  }
  catch {
    Write-ColorOutput "Failed to configure Git: $_" 'Red'
  }
}

function New-DevelopmentDirectories {
  param ([hashtable]$Config)
  if (-not $Config.CreateDirectories) { Write-ColorOutput "Skipping directory creation (disabled in config)" 'Yellow'; return $null }
  $devFolders = @('Projects', 'Projects\UnrealProjects', 'Projects\UnrealPlugins', 'Projects\UnrealAssets', 'Workspace', 'Development', 'GitHub', '.ssh', '.config', '.docker', 'Downloads\Development', 'Projects\UnrealPrototypes', 'Projects\UnrealTools')
  foreach ($folder in $devFolders) {
    $folderPath = Join-Path $env:USERPROFILE $folder
    if (Test-Path $folderPath) { Write-ColorOutput "Directory already exists: $folderPath" 'Green' }
    else { New-Item -ItemType Directory -Path $folderPath -Force | Out-Null; Write-ColorOutput "Created directory: $folderPath" 'Green' }
  }
}

function Set-EnvironmentVariables {
  param ([hashtable]$Config)
  Write-ColorOutput "Setting environment variables for Unreal Engine development..." 'Cyan'
  $envVars = @{
    'UE_ROOT'       = Join-Path $env:ProgramFiles "Epic Games"
    'UE_PROJECTS'   = Join-Path $env:USERPROFILE "Projects\UnrealProjects"
    'UE_ASSETS'     = Join-Path $env:USERPROFILE "Projects\UnrealAssets"
    'UE_PLUGINS'    = Join-Path $env:USERPROFILE "Projects\UnrealPlugins"
    'UE_PROTOTYPES' = Join-Path $env:USERPROFILE "Projects\UnrealPrototypes"
    'UE_TOOLS'      = Join-Path $env:USERPROFILE "Projects\UnrealTools"
    'PYTHON_HOME'   = if (Test-Path "$env:ProgramFiles\Python*") { (Get-ChildItem "$env:ProgramFiles" -Filter "Python*" | Where-Object { $_.PSIsContainer } | Sort-Object Name -Descending | Select-Object -First 1).FullName } else { Join-Path $env:ProgramFiles "Python" }
  }
  foreach ($var in $envVars.GetEnumerator()) {
    [System.Environment]::SetEnvironmentVariable($var.Key, $var.Value, 'Machine')
    Write-ColorOutput "Set environment variable: $($var.Key) = $($var.Value)" 'Yellow'
  }
}

function Set-PowerShellProfile {
  param ([hashtable]$Config)
  if (-not $Config.SetupPowershellProfile) { Write-ColorOutput "Skipping PowerShell profile setup (disabled in config)" 'Yellow'; return $null }
  if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
  $profileContent = @"
# Unreal Engine specific aliases and functions
# Profile generated by UE Setup Script v$SCRIPT_VERSION on $SCRIPT_TIMESTAMP
function Get-UnrealEngineVersions { Get-ChildItem (Join-Path `$env:ProgramFiles "Epic Games") -Filter "UE_*" | Where-Object { `$_.PSIsContainer } | Sort-Object Name }
function ue4 { Set-Location (Join-Path `$env:UE_ROOT 'UE_4.27') }
function ue5 { Set-Location (Join-Path `$env:UE_ROOT 'UE_5.4') }
function ue { `$versions = Get-UnrealEngineVersions; if (-not `$versions) { Write-Host "No Unreal Engine installations found" -ForegroundColor Red; return }; `$latest = `$versions | Select-Object -Last 1; Set-Location `$latest.FullName; Write-Host "Navigated to `$(`$latest.Name)" -ForegroundColor Green }
function ueprojects { Set-Location `$env:UE_PROJECTS }
function ueassets { Set-Location `$env:UE_ASSETS }
function ueplugins { Set-Location `$env:UE_PLUGINS }
function ueprototypes { Set-Location `$env:UE_PROTOTYPES }
function uetools { Set-Location `$env:UE_TOOLS }
function cdp { Set-Location (Join-Path `$env:USERPROFILE 'Projects') }
function cdw { Set-Location (Join-Path `$env:USERPROFILE 'Workspace') }
function cdg { Set-Location (Join-Path `$env:USERPROFILE 'GitHub') }
function gs { git status }
function gp { git pull }
function gps { git push }
function gc { git checkout `$args }
function gb { git branch }
function gl { git log --oneline --graph --decorate -10 }
function gcm { git commit -m `$args }
function Start-UEEditor { param([string]`$Version = "5.4"); `$exe = Join-Path `$env:UE_ROOT "UE_`$Version\Engine\Binaries\Win64\UnrealEditor.exe"; if (Test-Path `$exe) { & `$exe } else { Write-Host "Editor not found for UE `$Version" -ForegroundColor Red } }
function New-UEProject { param([Parameter(Mandatory=`$true)][string]`$ProjectName, [string]`$EngineVersion = "5.4", [string]`$TemplateName = "TP_Blank", [string]`$OutputPath = `$env:UE_PROJECTS); `$enginePath = Join-Path `$env:UE_ROOT "UE_`$EngineVersion"; if (-not (Test-Path `$enginePath)) { Write-Host "Engine version UE_`$EngineVersion not found!" -ForegroundColor Red; return }; `$fullOutputPath = Join-Path `$OutputPath `$ProjectName; `$engineExe = Join-Path `$enginePath "Engine\Binaries\Win64\UnrealEditor.exe"; if (-not (Test-Path `$engineExe)) { `$engineExe = Join-Path `$enginePath "Engine\Binaries\Win64\UE4Editor.exe" }; if (-not (Test-Path `$engineExe)) { Write-Host "Could not find Unreal Editor executable!" -ForegroundColor Red; return }; & `$engineExe `$fullOutputPath -projectFile="`$ProjectName.uproject" -template="`$TemplateName" -createonly; if (Test-Path `$fullOutputPath) { Write-Host "Project created successfully at: `$fullOutputPath" -ForegroundColor Green } else { Write-Host "Failed to create project!" -ForegroundColor Red } }
function Build-UEProject { param([Parameter(Mandatory=`$true)][string]`$ProjectPath); `$uproject = Get-ChildItem `$ProjectPath -Filter "*.uproject" | Select-Object -First 1; if (-not `$uproject) { Write-Host "No .uproject file found in `$ProjectPath" -ForegroundColor Red; return }; `$ueEditor = Get-ChildItem (Join-Path `$env:UE_ROOT "UE_*") -Recurse -Filter "UnrealEditor.exe" | Select-Object -First 1; if (`$ueEditor) { & `$ueEditor.FullName `$uproject.FullName -build; Write-Host "Building project: `$($uproject.FullName)" -ForegroundColor Green } else { Write-Host "Unreal Editor not found!" -ForegroundColor Red } }
"@
  Add-Content $PROFILE $profileContent -Force
  Write-ColorOutput "PowerShell profile configured with enhanced Unreal Engine aliases and functions!" 'Green'
}

function Test-Installation {
  param ([hashtable]$Config)
  if (-not $Config.ValidateInstallation) { Write-ColorOutput "Skipping installation validation (disabled in config)" 'Yellow'; return $null }
  Write-ColorOutput "`nPerforming final validation..." 'Cyan'
  $validationResults = @()
  $toolsToValidate = @(@{Name = 'git'; Arg = '--version'; Description = 'Git version control' }, @{Name = 'code'; Arg = '--version'; Description = 'Visual Studio Code' }, @{Name = 'python'; Arg = '--version'; Description = 'Python programming language' }, @{Name = 'node'; Arg = '--version'; Description = 'Node.js runtime' }, @{Name = 'cmake'; Arg = '--version'; Description = 'CMake build system' }, @{Name = 'docker'; Arg = '--version'; Description = 'Docker container platform' }, @{Name = 'blender'; Arg = '--version'; Description = 'Blender 3D modeling' })
  foreach ($tool in $toolsToValidate) {
    $result = Test-ToolVersion -Command $tool.Name -VersionArg $tool.Arg -Silent
    if ($result.Installed) { $validationResults += "$($tool.Name): OK ($($tool.Description) - v$($result.Version))" } else { $validationResults += "$($tool.Name): Not found or not working ($($tool.Description))" }
  }
  Write-ColorOutput "`n╔═══════════════════════════════════════╗" 'Cyan'
  Write-ColorOutput "║ Installation Summary                  ║" 'Cyan'
  Write-ColorOutput "╚═══════════════════════════════════════╝" 'Cyan'
  $validationResults | ForEach-Object { Write-ColorOutput $_ 'White' }
  $unrealInstalls = Get-ChildItem (Join-Path $env:ProgramFiles "Epic Games") -Filter "UE_*" -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | Sort-Object Name
  Write-ColorOutput "`nUnreal Engine Installations:" 'Cyan'
  if ($unrealInstalls) { $unrealInstalls | ForEach-Object { Write-ColorOutput "- $($_.Name)" 'White' } }
  else { Write-ColorOutput "- No Unreal Engine installations found. Please use Epic Games Launcher to install Unreal Engine." 'Yellow' }
  Write-ColorOutput "`nEnvironment Variables:" 'Cyan'
  foreach ($var in $envVars.GetEnumerator()) { Write-ColorOutput "- $($var.Key) = $($var.Value)" 'White' }
  Write-ColorOutput "`n╔═══════════════════════════════════════╗" 'Cyan'
  Write-ColorOutput "║ Setup Complete                        ║" 'Cyan'
  Write-ColorOutput "╚═══════════════════════════════════════╝" 'Cyan'
  Write-ColorOutput "Unreal Engine Development Environment has been set up successfully!" 'Green'
  Write-ColorOutput "Next steps:" 'White'
  Write-ColorOutput "1. Launch Epic Games Launcher to install Unreal Engine versions" 'White'
  Write-ColorOutput "2. Open a new PowerShell window to use enhanced aliases (e.g., 'ue', 'New-UEProject')" 'White'
  Write-ColorOutput "3. Explore artist tools in $env:UE_ASSETS and developer tools in $env:UE_TOOLS" 'White'
  Write-ColorOutput "4. Check logs at $($Config.LogPath) for details" 'White'
  Write-ColorOutput "5. Use 'Build-UEProject' to compile your projects" 'White'
}

#endregion

function Main {
  Start-Logging
  Show-WelcomeBanner
  Test-AndInstallChocolatey
  $config = Get-UserChoices -Config $defaultConfig
  if ($config.CreateBackup) { Backup-Environment -BackupPath $config.BackupPath }
  foreach ($version in $config.SelectedUnrealVersions) { Install-VisualStudio -UnrealVersion $version -Config $config }
  Install-EpicGamesLauncher -Config $config
  Install-DevTools -Config $config
  Install-ArtistTools -Config $config
  Install-UnrealExtras -Config $config
  Install-UnrealPythonDependencies -Config $config
  Set-GitConfiguration -Config $config
  New-DevelopmentDirectories -Config $config
  Set-EnvironmentVariables -Config $config
  Set-PowerShellProfile -Config $config
  Test-Installation -Config $config
  Write-ColorOutput "Setup completed successfully! Restart your system for all changes to take effect." 'Green'
}

try {
  Main
}
catch {
  Write-ColorOutput "Critical error occurred: $_" 'Red'
  Write-ColorOutput "Check logs at $($defaultConfig.LogPath) for details." 'Yellow'
  exit 1
}
finally {
  Stop-Transcript
}
