# Check if running as Administrator
$adminCheck = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$adminRole = [System.Security.Principal.WindowsPrincipal]::new($adminCheck)
if (-not $adminRole.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Error: Please run this script as Administrator!" -ForegroundColor Red
    exit
}

Write-Host "Starting Windows Development Environment Setup..." -ForegroundColor Cyan

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
        Write-Host "Added to $Scope PATH: $PathToAdd" -ForegroundColor Green
    }
}

# Function to update all installed packages
function Update-AllPackages {
    Write-Host "Updating all packages..." -ForegroundColor Cyan

    # Update Scoop and all apps
    Write-Host "Updating Scoop and its packages..." -ForegroundColor Yellow
    scoop update
    scoop update *

    # Update npm and global packages
    Write-Host "Updating npm and global packages..." -ForegroundColor Yellow
    npm install -g npm@latest
    npm update -g

    # Update pnpm
    Write-Host "Updating pnpm..." -ForegroundColor Yellow
    npm install -g pnpm@latest

    # Update Python and pip packages
    Write-Host "Updating pip and global packages..." -ForegroundColor Yellow
    python -m pip install --upgrade pip
    pip list --outdated --format=json | ConvertFrom-Json | ForEach-Object {
        python -m pip install --upgrade $_.name
    }

    Write-Host "All packages have been updated!" -ForegroundColor Green
}

# Install Scoop (Windows package manager)
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..." -ForegroundColor Yellow
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
} else {
    Write-Host "Updating Scoop..." -ForegroundColor Yellow
    scoop update
}

# Add Scoop to PATH
$scoopShimsPath = Join-Path $env:USERPROFILE "scoop\shims"
Add-ToPath -PathToAdd $scoopShimsPath -Scope 'User'

# Install essential tools with Scoop
Write-Host "Installing/Updating essential development tools..." -ForegroundColor Cyan
$scoopApps = @(
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
    'ruby'
    'go'
    'rust'
    'gcc'
    'kubectl'
    'terraform'
    'aws'
    'azure-cli'
    'github'
    'googlechrome'
    'firefox-developer'
    'microsoft-edge'
)

foreach ($app in $scoopApps) {
    Write-Host "Installing/Updating $app..." -ForegroundColor Yellow
    scoop install $app
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
)

foreach ($path in $paths) {
    Add-ToPath -PathToAdd $path -Scope 'Machine'
}

# Install Node.js global packages
Write-Host "Installing/Updating Node.js global packages..." -ForegroundColor Cyan
$nodePackages = @(
    'pnpm'
    'yarn'
    'typescript'
    'ts-node'
    'nodemon'
    'npm-check-updates'
    '@angular/cli'
    'create-react-app'
    '@vue/cli'
    'next'
    'nx'
    'eslint'
    'prettier'
    'serve'
)

foreach ($package in $nodePackages) {
    Write-Host "Installing/Updating $package globally..." -ForegroundColor Yellow
    npm install -g $package
}

# Install Python packages
Write-Host "Installing/Updating Python packages..." -ForegroundColor Cyan
$pythonPackages = @(
    'pip'
    'virtualenv'
    'pipenv'
    'poetry'
    'black'
    'pylint'
    'pytest'
    'django'
    'flask'
    'fastapi'
    'uvicorn'
    'jupyter'
    'requests'
    'pandas'
    'numpy'
)

foreach ($package in $pythonPackages) {
    Write-Host "Installing/Updating $package..." -ForegroundColor Yellow
    python -m pip install --upgrade $package
}

# Create development directories
$devFolders = @(
    'Projects'
    'Workspace'
    'Development'
    'GitHub'
    '.ssh'
    '.config'
)

foreach ($folder in $devFolders) {
    $folderPath = Join-Path $env:USERPROFILE $folder
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
        Write-Host "Created directory: $folderPath" -ForegroundColor Green
    }
}

# Configure Git
Write-Host "Configuring Git..." -ForegroundColor Cyan
git config --global core.autocrlf true
git config --global init.defaultBranch main
git config --global pull.rebase false

# Set up Windows Terminal settings
$terminalSettingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $terminalSettingsPath) {
    Write-Host "Configuring Windows Terminal..." -ForegroundColor Cyan
    $terminalSettings = Get-Content $terminalSettingsPath | ConvertFrom-Json
    $terminalSettings.profiles.defaults.font.face = "FiraCode NF"
    $terminalSettings.profiles.defaults.font.size = 12
    $terminalSettings | ConvertTo-Json -Depth 32 | Set-Content $terminalSettingsPath
}

# Create PowerShell profile with auto-update function
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

Add-Content $PROFILE @"
# Initialize Oh My Posh with default theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\agnoster.omp.json" | Invoke-Expression

# Custom aliases
Set-Alias -Name g -Value git
Set-Alias -Name py -Value python
Set-Alias -Name code -Value code-insiders
Set-Alias -Name k -Value kubectl

# Auto-update function
function Update-DevEnv {
    Write-Host "Updating development environment..." -ForegroundColor Cyan
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
Write-Host "Setting environment variables..." -ForegroundColor Cyan
$envVars = @{
    'PYTHON_HOME' = Join-Path $env:USERPROFILE "scoop\apps\python\current"
    'NODE_PATH' = Join-Path $env:USERPROFILE "scoop\apps\nodejs-lts\current"
    'GOPATH' = Join-Path $env:USERPROFILE "go"
    'CARGO_HOME' = Join-Path $env:USERPROFILE ".cargo"
}

foreach ($var in $envVars.GetEnumerator()) {
    [System.Environment]::SetEnvironmentVariable($var.Key, $var.Value, 'Machine')
}

# Create scheduled task for auto-updates
$taskName = "DevelopmentEnvironmentUpdate"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command Update-DevEnv"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9AM
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings
} else {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings
}

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path', 'User')

Write-Host @"

Setup complete! Your development environment has been configured with:

1. Package Managers and Core Tools:
   - Scoop with multiple buckets
   - Git, curl, wget, unzip, 7zip
   - Windows Terminal with FiraCode NF font
   - PowerToys and other utilities

2. Development Environments:
   - Node.js LTS with npm, pnpm, yarn
   - Python with pip, virtualenv, pipenv, poetry
   - Go, Rust, Ruby, GCC
   - VS Code

3. Containers and Cloud:
   - Docker and Docker Compose
   - Kubernetes tools
   - AWS CLI, Azure CLI
   - Terraform

4. Browsers and Tools:
   - Chrome, Firefox Developer Edition, Edge
   - Postman
   - GitHub CLI

5. Configurations:
   - PowerShell profile with aliases and functions
   - Git configuration
   - Windows Terminal settings
   - Development directories
   - Environment variables

6. Auto-Update Features:
   - Weekly scheduled updates
   - Manual update available via 'Update-DevEnv' command
   - Automatic package updates for all installed tools

Next steps:
1. Restart your terminal
2. Run 'refreshenv' to reload environment variables
3. Run 'Update-DevEnv' to ensure all packages are at their latest versions
4. Start using the new aliases and functions in PowerShell

Your development environment will automatically update every Monday at 9 AM.
You can manually update anytime by running 'Update-DevEnv' in PowerShell.

"@ -ForegroundColor Cyan

Write-Host "Please restart your terminal for all changes to take effect." -ForegroundColor Green
