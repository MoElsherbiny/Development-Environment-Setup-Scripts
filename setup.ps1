# Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script version and timestamp
$SCRIPT_VERSION = "2.0.0"
$SCRIPT_TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

# Add these functions after Write-ColorOutput function definition
function Test-ToolVersion {
    param (
        [string]$Command,
        [string]$MinVersion,
        [string]$VersionArg = '--version'
    )
    try {
        $version = & $Command $VersionArg 2>&1
        Write-ColorOutput "$Command version: $version" 'Gray'
        return $true
    }
    catch {
        return $false
    }
}

# Add this function after the Test-ToolVersion function
function Test-PathEntry {
    param (
        [string]$PathEntry,
        [ValidateSet('User', 'Machine')]$Scope
    )

    $currentPath = [System.Environment]::GetEnvironmentVariable('Path', $Scope)
    $pathsArray = $currentPath -split ';' | Where-Object { $_ }

    $exists = $pathsArray -contains $PathEntry
    if (-not $exists) {
        Write-ColorOutput "WARNING: $PathEntry is missing from $Scope PATH" 'Yellow'
        return $false
    }

    # Verify the path actually exists
    if (-not (Test-Path $PathEntry)) {
        Write-ColorOutput "ERROR: $PathEntry in $Scope PATH does not exist on disk" 'Red'
        return $false
    }

    Write-ColorOutput "Verified $PathEntry in $Scope PATH" 'Green'
    return $true
}

# Add this function to verify all required paths
function Test-AllPaths {
    Write-ColorOutput "Verifying PATH entries..." 'Cyan'

    $requiredPaths = @{
        'Machine' = @(
            (Join-Path $env:USERPROFILE "scoop\apps\git\current\cmd")
            (Join-Path $env:USERPROFILE "scoop\apps\python\current")
            (Join-Path $env:USERPROFILE "scoop\apps\python\current\Scripts")
            (Join-Path $env:USERPROFILE "scoop\apps\nodejs-lts\current")
            (Join-Path $env:USERPROFILE "scoop\apps\go\current\bin")
            (Join-Path $env:USERPROFILE "scoop\apps\ruby\current\bin")
            (Join-Path $env:USERPROFILE "scoop\apps\rust\current\bin")
            (Join-Path $env:USERPROFILE "scoop\apps\java\current\bin")
        )
        'User'    = @(
            (Join-Path $env:USERPROFILE "scoop\shims")
            (Join-Path $env:USERPROFILE ".cargo\bin")
            (Join-Path $env:USERPROFILE "go\bin")
        )
    }

    $missingPaths = @{
        'Machine' = @()
        'User'    = @()
    }

    foreach ($scope in $requiredPaths.Keys) {
        foreach ($path in $requiredPaths[$scope]) {
            if (-not (Test-PathEntry -PathEntry $path -Scope $scope)) {
                $missingPaths[$scope] += $path
            }
        }
    }

    return $missingPaths
}

function Confirm-Installation {
    param (
        [string]$Tool,
        [string]$InstallPath
    )
    if (Test-Path $InstallPath) {
        Write-ColorOutput "$Tool is already installed at: $InstallPath" 'Green'
        return $true
    }
    return $false
}

# Check if running as Administrator
$adminCheck = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$adminRole = [System.Security.Principal.WindowsPrincipal]::new($adminCheck)
if (-not $adminRole.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-ColorOutput "Error: Please run this script as Administrator!" 'Red'
    exit
}

# Add this right after the administrator check
$installedTools = @{}

Write-ColorOutput "Starting Windows Development Environment Setup v$SCRIPT_VERSION..." 'Cyan'

# Function to add to PATH without duplicates
function Add-ToPath {
    param (
        [string]$PathToAdd,
        [ValidateSet('User', 'Machine')]$Scope
    )

    $currentPath = [System.Environment]::GetEnvironmentVariable('Path', $Scope)
    $pathsArray = $currentPath -split ';' | Where-Object { $_ }

    if ($pathsArray -notcontains $PathToAdd) {
        $newPath = ($pathsArray + $PathToAdd) -join ';'
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, $Scope)
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [System.Environment]::GetEnvironmentVariable('Path', 'User')
        Write-ColorOutput "Added to $Scope PATH: $PathToAdd" 'Green'
    }
}

# Function to update all installed packages
function Update-AllPackages {
    Write-ColorOutput "Updating all packages..." 'Cyan'

    try {
        # Update Scoop and all apps
        Write-ColorOutput "Updating Scoop and its packages..." 'Yellow'
        scoop update
        scoop update *

        # Update npm and global packages
        Write-ColorOutput "Updating npm and global packages..." 'Yellow'
        npm install -g npm@latest
        npm update -g

        # Update pnpm
        Write-ColorOutput "Updating pnpm..." 'Yellow'
        npm install -g pnpm@latest

        # Update Python and pip packages
        Write-ColorOutput "Updating pip and global packages..." 'Yellow'
        python -m pip install --upgrade pip
        pip list --outdated --format=json | ConvertFrom-Json | ForEach-Object {
            python -m pip install --upgrade $_.name
        }

        Write-ColorOutput "All packages have been updated!" 'Green'
    }
    catch {
        Write-ColorOutput "Error updating packages: $_" 'Red'
    }
}

# Install Scoop (Windows package manager)
try {
    # Add these version checks before Scoop installation
    if (Test-ToolVersion 'scoop') {
        $installedTools['scoop'] = $true
        Write-ColorOutput "Scoop is already installed, checking for updates..." 'Green'
    }

    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-ColorOutput "Installing Scoop..." 'Yellow'
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

        # Set Scoop path
        $env:SCOOP = Join-Path $env:USERPROFILE "scoop"
        [System.Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')

        # Add Scoop buckets
        scoop bucket add extras
        scoop bucket add versions
        scoop bucket add nerd-fonts
        scoop bucket add java
        scoop bucket add main
    }
    else {
        Write-ColorOutput "Updating Scoop..." 'Yellow'
        scoop update
    }
}
catch {
    Write-ColorOutput "Error setting up Scoop: $_" 'Red'
    exit
}

# Add Scoop to PATH
$scoopShimsPath = Join-Path $env:USERPROFILE "scoop\shims"
Add-ToPath -PathToAdd $scoopShimsPath -Scope 'User'

# Install essential tools with Scoop
Write-ColorOutput "Installing/Updating essential development tools..." 'Cyan'
$scoopApps = @(
    # Development Tools
    'git'
    'curl'
    'wget'
    'unzip'
    '7zip'
    'nodejs-lts'
    'python'
    'vscode'
    'docker'
    'docker-compose'
    'postman'
    'windows-terminal'
    'oh-my-posh'
    'firacode-nf'
    'gsudo'
    'powertoys'
    'jq'

    # Programming Languages
    'ruby'
    'go'
    'rust'
    'gcc'
    'openjdk17'
    'kotlin'
    'dotnet-sdk'

    # Cloud & Infrastructure
    'kubectl'
    'terraform'
    'aws'
    'azure-cli'
    'github'
    'helm'
    'k9s'
    'minikube'

    # Databases
    'mysql'
    'postgresql'
    'mongodb'
    'redis'

    # Browsers
    'googlechrome'
    'firefox-developer'
    'microsoft-edge'

    # Additional Tools
    'mingw'
    'make'
    'cmake'
    'llvm'
    'ninja'
    'gradle'
    'maven'
    'insomnia'
    'wireshark'
    'ngrok'
)

# Add these checks before installing each Scoop app
foreach ($app in $scoopApps) {
    $appPath = Join-Path $env:USERPROFILE "scoop\apps\$app\current"
    if (Confirm-Installation $app $appPath) {
        Write-ColorOutput "Updating $app..." 'Yellow'
        scoop update $app
    }
    else {
        Write-ColorOutput "Installing $app..." 'Yellow'
        scoop install $app
    }
}

# Ensure VS Code is installed
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-ColorOutput "VS Code is installed. Configuring settings and extensions..." 'Cyan'

    # Set up VS Code settings
    $vsCodeSettingsPath = Join-Path $env:APPDATA "Code\User\settings.json"
    $sourceSettingsPath = Join-Path $PSScriptRoot "settings.json"

    # Create the directory if it doesn't exist
    New-Item -ItemType Directory -Force -Path (Split-Path $vsCodeSettingsPath) | Out-Null

    if (Test-Path $sourceSettingsPath) {
        Copy-Item -Path $sourceSettingsPath -Destination $vsCodeSettingsPath -Force
        Write-ColorOutput "VS Code settings configured successfully!" 'Green'
    }

    # Install extensions from extensions.txt
    $extensionsFile = Join-Path $PSScriptRoot "extensions.txt"
    if (Test-Path $extensionsFile) {
        Get-Content $extensionsFile | ForEach-Object {
            $extension = $_
            if (-not [string]::IsNullOrWhiteSpace($extension)) {
                Write-ColorOutput "Installing VS Code extension: $extension" 'Yellow'
                code --install-extension $extension --force
            }
        }
        Write-ColorOutput "VS Code extensions installed successfully!" 'Green'
    }
}
else {
    Write-ColorOutput "VS Code is not installed. Skipping configuration." 'Red'
}

# Add development tools to PATH
$paths = @(
    (Join-Path $env:USERPROFILE "scoop\apps\git\current\cmd")
    (Join-Path $env:USERPROFILE "scoop\apps\python\current")
    (Join-Path $env:USERPROFILE "scoop\apps\python\current\Scripts")
    (Join-Path $env:USERPROFILE "scoop\apps\nodejs-lts\current")
    (Join-Path $env:USERPROFILE "scoop\apps\go\current\bin")
    (Join-Path $env:USERPROFILE "scoop\apps\ruby\current\bin")
    (Join-Path $env:USERPROFILE "scoop\apps\rust\current\bin")
    (Join-Path $env:USERPROFILE "scoop\apps\java\current\bin")
)

foreach ($path in $paths) {
    Add-ToPath -PathToAdd $path -Scope 'Machine'
}

# Install Node.js global packages
Write-ColorOutput "Installing/Updating Node.js global packages..." 'Cyan'
$nodePackages = @(
    # Package Managers
    'pnpm'
    'yarn'

    # Development Tools
    'typescript'
    'ts-node'
    'nodemon'
    'npm-check-updates'

    # Frameworks and CLIs
    '@angular/cli'
    'create-react-app'
    '@vue/cli'
    'next'
    'nx'

    # Code Quality
    'eslint'
    'prettier'

    # Utilities
    'serve'
    'vercel'
    'netlify-cli'
    'firebase-tools'

    # Build Tools
    'webpack-cli'
    'vite'
    'turbo'

    # Testing
    'jest'
    'cypress'
)

# Add these checks before installing Node.js packages
foreach ($package in $nodePackages) {
    if (Test-ToolVersion $package) {
        Write-ColorOutput "Updating $package..." 'Yellow'
        npm update -g $package
    }
    else {
        Write-ColorOutput "Installing $package..." 'Yellow'
        npm install -g $package
    }
}

# Install Python packages
Write-ColorOutput "Installing/Updating Python packages..." 'Cyan'
$pythonPackages = @(
    # Package Management
    'pip'
    'virtualenv'
    'pipenv'
    'poetry'

    # Code Quality
    'black'
    'pylint'
    'mypy'
    'flake8'

    # Testing
    'pytest'
    'pytest-cov'
    'pytest-asyncio'

    # Web Frameworks
    'django'
    'flask'
    'fastapi'
    'uvicorn'

    # Data Science
    'jupyter'
    'pandas'
    'numpy'
    'matplotlib'
    'seaborn'

    # Utilities
    'requests'
    'httpx'
    'aiohttp'
    'beautifulsoup4'
    'rich'
)

# Add these checks before installing Python packages
foreach ($package in $pythonPackages) {
    if (python -m pip show $package 2>&1) {
        Write-ColorOutput "Updating $package..." 'Yellow'
        python -m pip install --upgrade $package
    }
    else {
        Write-ColorOutput "Installing $package..." 'Yellow'
        python -m pip install $package
    }
}

# Create development directories
$devFolders = @(
    'Projects'
    'Workspace'
    'Development'
    'GitHub'
    '.ssh'
    '.config'
    '.docker'
    'Downloads\Development'
)

# Add these checks before creating directories
foreach ($folder in $devFolders) {
    $folderPath = Join-Path $env:USERPROFILE $folder
    if (Test-Path $folderPath) {
        Write-ColorOutput "Directory already exists: $folderPath" 'Green'
    }
    else {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
        Write-ColorOutput "Created directory: $folderPath" 'Green'
    }
}

# Configure Git
Write-ColorOutput "Configuring Git..." 'Cyan'
git config --global core.autocrlf true
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.fileMode false
git config --global core.symlinks true
git config --global core.longpaths true
git config --global core.ignorecase false
git config --global core.safecrlf warn
git config --global credential.helper wincred

# Set up Windows Terminal settings
$terminalSettingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $terminalSettingsPath) {
    Write-ColorOutput "Configuring Windows Terminal..." 'Cyan'
    $terminalSettings = Get-Content $terminalSettingsPath | ConvertFrom-Json
    $terminalSettings.profiles.defaults.font.face = "FiraCode NF"
    $terminalSettings.profiles.defaults.font.size = 12
    $terminalSettings.profiles.defaults.colorScheme = "One Half Dark"
    $terminalSettings | ConvertTo-Json -Depth 32 | Set-Content $terminalSettingsPath
}

# Create PowerShell profile with auto-update function
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

Add-Content $PROFILE @"
# Initialize Oh My Posh with default theme
oh-my-posh init pwsh --config `"`$env:POSH_THEMES_PATH\agnoster.omp.json`" | Invoke-Expression

# Custom aliases
Set-Alias -Name g -Value git
Set-Alias -Name py -Value python
Set-Alias -Name code -Value code-insiders
Set-Alias -Name k -Value kubectl

# Auto-update function
function Update-DevEnv {
    Write-Host `"Updating development environment...`" -ForegroundColor Cyan
    # Function content will be added by the installation script
    $(Get-Content Function:\Update-AllPackages)
}

# Navigation shortcuts
function cdp { Set-Location (Join-Path `$env:USERPROFILE 'Projects') }
function cdw { Set-Location (Join-Path `$env:USERPROFILE 'Workspace') }
function cdg { Set-Location (Join-Path `$env:USERPROFILE 'GitHub') }

# Docker shortcuts
function dps { docker ps }
function dcp { docker-compose up }
function dcpd { docker-compose up -d }
function dcd { docker-compose down }

# Kubernetes shortcuts
function kc { kubectl }
function kgp { kubectl get pods }
function kgs { kubectl get services }
function kgd { kubectl get deployments }

# Git shortcuts
function gs { git status }
function gp { git pull }
function gps { git push }
function gc { git checkout }
function gb { git branch }
"@

# Set environment variables
Write-ColorOutput "Setting environment variables..." 'Cyan'
$envVars = @{
    'PYTHON_HOME' = Join-Path $env:USERPROFILE "scoop\apps\python\current"
    'NODE_PATH'   = Join-Path $env:USERPROFILE "scoop\apps\nodejs-lts\current"
    'GOPATH'      = Join-Path $env:USERPROFILE "go"
    'CARGO_HOME'  = Join-Path $env:USERPROFILE ".cargo"
    'JAVA_HOME'   = Join-Path $env:USERPROFILE "scoop\apps\openjdk17\current"
    'MAVEN_HOME'  = Join-Path $env:USERPROFILE "scoop\apps\maven\current"
}

# Add these checks before setting environment variables
foreach ($var in $envVars.GetEnumerator()) {
    $currentValue = [System.Environment]::GetEnvironmentVariable($var.Key, 'Machine')
    if ($currentValue -eq $var.Value) {
        Write-ColorOutput "Environment variable $($var.Key) already set correctly" 'Green'
    }
    else {
        [System.Environment]::SetEnvironmentVariable($var.Key, $var.Value, 'Machine')
        Write-ColorOutput "Updated environment variable: $($var.Key)" 'Yellow'
    }
}

# Add this after setting environment variables but before the final validation
Write-ColorOutput "`nVerifying PATH configurations..." 'Cyan'
$missingPaths = Test-AllPaths

# Attempt to fix missing PATH entries
if ($missingPaths.Machine.Count -gt 0 -or $missingPaths.User.Count -gt 0) {
    Write-ColorOutput "`nAttempting to fix missing PATH entries..." 'Yellow'

    foreach ($path in $missingPaths.Machine) {
        if (Test-Path $path) {
            Write-ColorOutput "Adding to Machine PATH: $path" 'Yellow'
            Add-ToPath -PathToAdd $path -Scope 'Machine'
        }
    }

    foreach ($path in $missingPaths.User) {
        if (Test-Path $path) {
            Write-ColorOutput "Adding to User PATH: $path" 'Yellow'
            Add-ToPath -PathToAdd $path -Scope 'User'
        }
    }

    # Verify fixes
    $remainingMissing = Test-AllPaths
    if ($remainingMissing.Machine.Count -eq 0 -and $remainingMissing.User.Count -eq 0) {
        Write-ColorOutput "All PATH entries have been fixed!" 'Green'
    }
    else {
        Write-ColorOutput "Some PATH entries could not be fixed. Manual intervention may be required." 'Red'
        foreach ($scope in $remainingMissing.Keys) {
            foreach ($path in $remainingMissing[$scope]) {
                Write-ColorOutput "Still missing from $scope PATH: $path" 'Red'
            }
        }
    }
}

# Create scheduled task for auto-updates
$taskName = "DevelopmentEnvironmentUpdate"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command Update-DevEnv"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9AM
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

if (Get-ScheduledTask -TaskName $taskName -ErrorAction Silent) {
    Write-ColorOutput "Updating scheduled task..." 'Yellow'
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings
}
else {
    Write-ColorOutput "Creating scheduled task..." 'Yellow'
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings
}

# Add final validation at the end of the script
Write-ColorOutput "Performing final validation..." 'Cyan'
$validationResults = @()

$toolsToValidate = @(
    @{Name = 'git'; Arg = '--version' },
    @{Name = 'node'; Arg = '--version' },
    @{Name = 'python'; Arg = '--version' },
    @{Name = 'docker'; Arg = '--version' },
    @{Name = 'code'; Arg = '--version' },
    @{Name = 'kubectl'; Arg = 'version --client' }
)

foreach ($tool in $toolsToValidate) {
    if (Test-ToolVersion $tool.Name -VersionArg $tool.Arg) {
        $validationResults += "$($tool.Name): OK"
    }
    else {
        $validationResults += "$($tool.Name): Not found or not working"
    }
}

# Add PATH validation results to the final output
$validationResults += ""
$validationResults += "PATH Configuration: $(if ($pathValidation['PATH Configuration']) { 'OK' } else { 'Issues Found' })"

Write-ColorOutput "`nInstallation Status:" 'Cyan'
$validationResults | ForEach-Object { Write-ColorOutput $_ 'White' }
