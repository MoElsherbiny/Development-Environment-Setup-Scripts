# Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script metadata
$SCRIPT_VERSION = "5.0.0"
$SCRIPT_TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$SCRIPT_LOG_PATH_BASE = Join-Path $env:TEMP "dev-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Function to ensure unique log file name
function Get-UniqueLogPath {
    param ([string]$BasePath)
    $counter = 0
    $logPath = $BasePath
    while ((Test-Path $logPath) -and (Get-Item $logPath -ErrorAction SilentlyContinue | Get-Process -ErrorAction SilentlyContinue)) {
        $counter++
        $logPath = $BasePath -replace '\.log$', "_$counter.log"
    }
    return $logPath
}

$SCRIPT_LOG_PATH = Get-UniqueLogPath $SCRIPT_LOG_PATH_BASE

# Start transcript logging
Start-Transcript -Path $SCRIPT_LOG_PATH -Append -Force

# Function to write colored output (no manual log writing, relies on transcript)
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White',
        [switch]$NoNewLine
    )
    Write-Host $Message -ForegroundColor $Color -NoNewLine:$NoNewLine
    # Transcript captures this automatically, no need for Add-Content
}

# Function to test tool version
function Test-ToolVersion {
    param (
        [string]$Command,
        [string]$MinVersion = "",
        [string]$VersionArg = '--version',
        [switch]$Silent
    )
    try {
        $version = & $Command $VersionArg 2>&1
        if (-not $Silent) {
            Write-ColorOutput "$Command version: $version" 'Gray'
        }
        if ($MinVersion -and $version -match '(\d+\.\d+\.\d+)') {
            $versionNum = [version]$Matches[1]
            $minVersionNum = [version]$MinVersion
            return $versionNum -ge $minVersionNum
        }
        return $true
    }
    catch {
        if (-not $Silent) {
            Write-ColorOutput "Could not detect ${Command}: $_" 'Gray'
        }
        return $false
    }
}

# Function to test PATH entry
function Test-PathEntry {
    param (
        [string]$PathEntry,
        [ValidateSet('User', 'Machine')]$Scope
    )
    $currentPath = [System.Environment]::GetEnvironmentVariable('Path', $Scope)
    $pathsArray = $currentPath -split ';' | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') }
    $PathEntry = $PathEntry.TrimEnd('\')
    $exists = $pathsArray -contains $PathEntry
    if (-not $exists) {
        Write-ColorOutput "WARNING: $PathEntry is missing from $Scope PATH" 'Yellow'
        return $false
    }
    if (-not (Test-Path $PathEntry)) {
        Write-ColorOutput "ERROR: $PathEntry in $Scope PATH does not exist on disk" 'Red'
        return $false
    }
    Write-ColorOutput "Verified $PathEntry in $Scope PATH" 'Green'
    return $true
}

# Function to verify all required paths
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

# Function to confirm installation
function Confirm-Installation {
    param (
        [string]$Tool,
        [string]$InstallPath,
        [string]$CommandName = $Tool,
        [string]$VersionArg = '--version'
    )
    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        if (Test-ToolVersion -Command $CommandName -VersionArg $VersionArg -Silent) {
            Write-ColorOutput "$Tool is already installed and working" 'Green'
            return $true
        }
    }
    if (Test-Path $InstallPath) {
        Write-ColorOutput "$Tool is installed at: $InstallPath but may not be in PATH" 'Yellow'
        return $true
    }
    Write-ColorOutput "$Tool is not installed" 'Yellow'
    return $false
}

# Function to add to PATH without duplicates
function Add-ToPath {
    param (
        [string]$PathToAdd,
        [ValidateSet('User', 'Machine')]$Scope
    )
    $PathToAdd = $PathToAdd.TrimEnd('\')
    $currentPath = [System.Environment]::GetEnvironmentVariable('Path', $Scope)
    $pathsArray = $currentPath -split ';' | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') }
    if ($pathsArray -notcontains $PathToAdd) {
        $newPath = ($pathsArray + $PathToAdd) -join ';'
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, $Scope)
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                    [System.Environment]::GetEnvironmentVariable('Path', 'User')
        Write-ColorOutput "Added to $Scope PATH: $PathToAdd" 'Green'
        return $true
    }
    Write-ColorOutput "$PathToAdd already in $Scope PATH" 'Gray'
    return $false
}

# Function to update all installed packages
function Update-AllPackages {
    [CmdletBinding()]
    param()
    Write-ColorOutput "Updating all packages..." 'Cyan'
    $updateErrors = @()
    try {
        Write-ColorOutput "Updating Scoop and its packages..." 'Yellow'
        try {
            scoop update
            scoop update *
        }
        catch {
            $updateErrors += "Scoop update failed: $_"
        }
        if (Test-ToolVersion 'npm' -Silent) {
            Write-ColorOutput "Updating npm and global packages..." 'Yellow'
            try {
                npm install -g npm@latest
                npm update -g
            }
            catch {
                $updateErrors += "npm update failed: $_"
            }
        }
        if (Test-ToolVersion 'pnpm' -Silent) {
            Write-ColorOutput "Updating pnpm..." 'Yellow'
            try {
                npm install -g pnpm@latest
            }
            catch {
                $updateErrors += "pnpm update failed: $_"
            }
        }
        if (Test-ToolVersion 'python' -Silent) {
            Write-ColorOutput "Updating pip and global packages..." 'Yellow'
            try {
                python -m pip install --upgrade pip
                pip list --outdated --format=json | ConvertFrom-Json | ForEach-Object {
                    python -m pip install --upgrade $_.name
                }
            }
            catch {
                $updateErrors += "Python/pip update failed: $_"
            }
        }
        if (Test-ToolVersion 'winget' -VersionArg '--version' -Silent) {
            Write-ColorOutput "Updating winget packages..." 'Yellow'
            try {
                winget upgrade --all --silent
            }
            catch {
                $updateErrors += "Winget upgrade failed: $_"
            }
        }
        if ($updateErrors.Count -eq 0) {
            Write-ColorOutput "All packages have been updated!" 'Green'
        }
        else {
            Write-ColorOutput "Updates completed with some errors:" 'Yellow'
            foreach ($error in $updateErrors) {
                Write-ColorOutput "  - $error" 'Red'
            }
        }
    }
    catch {
        Write-ColorOutput "Error in main update process: $_" 'Red'
    }
}

# Main script execution
try {
    # Check if running as Administrator
    $adminCheck = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $adminRole = [System.Security.Principal.WindowsPrincipal]::new($adminCheck)
    if (-not $adminRole.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-ColorOutput "Error: Please run this script as Administrator!" 'Red'
        Write-ColorOutput "Right-click on PowerShell and select 'Run as Administrator', then run this script again." 'Yellow'
        Stop-Transcript
        exit 1
    }

    # Show welcome message and script info
    Write-ColorOutput "`n=========================================================" 'Cyan'
    Write-ColorOutput "Windows Development Environment Setup v$SCRIPT_VERSION" 'Cyan'
    Write-ColorOutput "Started at: $SCRIPT_TIMESTAMP" 'Cyan'
    Write-ColorOutput "Logging to: $SCRIPT_LOG_PATH" 'Cyan'
    Write-ColorOutput "=========================================================`n" 'Cyan'

    # Check for internet connectivity
    Write-ColorOutput "Checking Internet connectivity..." 'Cyan'
    if (-not (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet)) {
        Write-ColorOutput "WARNING: Internet connection appears to be down or unreliable!" 'Red'
        $response = Read-Host "Do you want to continue anyway? (y/n)"
        if ($response -ne 'y') {
            Write-ColorOutput "Setup aborted due to connectivity issues." 'Red'
            Stop-Transcript
            exit 1
        }
        Write-ColorOutput "Continuing despite connectivity issues. Some installations might fail." 'Yellow'
    }

    # Initialize installed tools tracking
    $script:installedTools = @{}
    $script:failed = @()
    $script:skipped = @()

    # Install Scoop (Windows package manager)
    try {
        Write-ColorOutput "Checking for Scoop..." 'Cyan'
        $scoopPath = Join-Path $env:USERPROFILE "scoop\shims\scoop.cmd"
        if (Test-Path $scoopPath -and (Test-ToolVersion 'scoop' -Silent)) {
            $script:installedTools['scoop'] = $true
            Write-ColorOutput "Scoop is already installed, updating..." 'Green'
            scoop update
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "Scoop update failed" 'Yellow'
            }
            else {
                Write-ColorOutput "Scoop updated successfully" 'Green'
            }
        }
        else {
            Write-ColorOutput "Installing Scoop..." 'Yellow'
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
            if ($LASTEXITCODE -eq 0) {
                $env:SCOOP = Join-Path $env:USERPROFILE "scoop"
                [System.Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
                $script:installedTools['scoop'] = $true
                Write-ColorOutput "Scoop installed successfully" 'Green'
            }
            else {
                throw "Scoop installation failed with exit code $LASTEXITCODE"
            }
        }

        # Add Scoop buckets
        if ($script:installedTools['scoop']) {
            Write-ColorOutput "Adding Scoop buckets..." 'Yellow'
            $buckets = @('main', 'extras', 'versions', 'nerd-fonts', 'java')
            foreach ($bucket in $buckets) {
                scoop bucket add $bucket 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "Added bucket: $bucket" 'Green'
                }
                else {
                    Write-ColorOutput "Failed to add bucket $bucket (might already exist)" 'Yellow'
                }
            }
        }
    }
    catch {
        Write-ColorOutput "Error setting up Scoop: $_" 'Red'
        $script:failed += 'scoop'
        Stop-Transcript
        exit 1  # Scoop is critical, exit if it fails
    }

    # Add Scoop to PATH
    $scoopShimsPath = Join-Path $env:USERPROFILE "scoop\shims"
    Add-ToPath -PathToAdd $scoopShimsPath -Scope 'User'

    # Install essential tools with Scoop
    Write-ColorOutput "`nInstalling/Updating essential development tools..." 'Cyan'
    $scoopApps = @(
        @{name = 'git'; cmd = 'git'; args = '--version' }
        @{name = 'curl'; cmd = 'curl'; args = '--version' }
        @{name = 'wget'; cmd = 'wget'; args = '--version' }
        @{name = 'unzip'; cmd = 'unzip'; args = '-v' }
        @{name = '7zip'; cmd = '7z'; args = '--help' }
        @{name = 'nodejs-lts'; cmd = 'node'; args = '--version' }
        @{name = 'python'; cmd = 'python'; args = '--version' }
        @{name = 'vscode'; cmd = 'code'; args = '--version' }
        @{name = 'docker'; cmd = 'docker'; args = '--version' }
        @{name = 'docker-compose'; cmd = 'docker-compose'; args = '--version' }
        @{name = 'postman'; cmd = 'postman'; args = '' }
        @{name = 'windows-terminal'; cmd = 'wt'; args = '-v' }
        @{name = 'oh-my-posh'; cmd = 'oh-my-posh'; args = '--version' }
        @{name = 'firacode-nf'; cmd = ''; args = '' }
        @{name = 'gsudo'; cmd = 'gsudo'; args = '--version' }
        @{name = 'powertoys'; cmd = ''; args = '' }
        @{name = 'jq'; cmd = 'jq'; args = '--version' }
        @{name = 'ruby'; cmd = 'ruby'; args = '--version' }
        @{name = 'go'; cmd = 'go'; args = 'version' }
        @{name = 'rust'; cmd = 'rustc'; args = '--version' }
        @{name = 'gcc'; cmd = 'gcc'; args = '--version' }
        @{name = 'openjdk17'; cmd = 'java'; args = '--version' }
        @{name = 'kotlin'; cmd = 'kotlin'; args = '-version' }
        @{name = 'dotnet-sdk'; cmd = 'dotnet'; args = '--version' }
        @{name = 'kubectl'; cmd = 'kubectl'; args = 'version --client' }
        @{name = 'terraform'; cmd = 'terraform'; args = 'version' }
        @{name = 'aws'; cmd = 'aws'; args = '--version' }
        @{name = 'azure-cli'; cmd = 'az'; args = 'version' }
        @{name = 'github'; cmd = 'gh'; args = '--version' }
        @{name = 'helm'; cmd = 'helm'; args = 'version' }
        @{name = 'k9s'; cmd = 'k9s'; args = 'version' }
        @{name = 'minikube'; cmd = 'minikube'; args = 'version' }
        @{name = 'mysql'; cmd = 'mysql'; args = '--version' }
        @{name = 'postgresql'; cmd = 'psql'; args = '--version' }
        @{name = 'mongodb'; cmd = 'mongo'; args = '--version' }
        @{name = 'redis'; cmd = 'redis-server'; args = '--version' }
        @{name = 'googlechrome'; cmd = ''; args = ''; useWinget = $true; wingetId = 'Google.Chrome' }
        @{name = 'firefox-developer'; cmd = ''; args = ''; useWinget = $true; wingetId = 'Mozilla.Firefox.DeveloperEdition' }
        @{name = 'microsoft-edge-dev'; cmd = ''; args = ''; useWinget = $true; wingetId = 'Microsoft.Edge.Dev' }
        @{name = 'brave'; cmd = ''; args = ''; useWinget = $true; wingetId = 'BraveSoftware.BraveBrowser' }
        @{name = 'mingw'; cmd = 'gcc'; args = '--version' }
        @{name = 'make'; cmd = 'make'; args = '--version' }
        @{name = 'cmake'; cmd = 'cmake'; args = '--version' }
        @{name = 'llvm'; cmd = 'clang'; args = '--version' }
        @{name = 'ninja'; cmd = 'ninja'; args = '--version' }
        @{name = 'gradle'; cmd = 'gradle'; args = '--version' }
        @{name = 'maven'; cmd = 'mvn'; args = '--version' }
        @{name = 'insomnia'; cmd = ''; args = '' }
        @{name = 'wireshark'; cmd = ''; args = '' }
        @{name = 'ngrok'; cmd = 'ngrok'; args = 'version' }
    )

    foreach ($app in $scoopApps) {
        $appName = $app.name
        $appPath = Join-Path $env:USERPROFILE "scoop\apps\$appName\current"
        if ($app.useWinget -and (Test-ToolVersion 'winget' -VersionArg '--version' -Silent)) {
            Write-ColorOutput "Checking $appName using winget..." 'Yellow'
            try {
                winget list --id $app.wingetId --exact | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "Updating $appName via winget..." 'Yellow'
                    winget upgrade --id $app.wingetId --silent
                    $script:installedTools[$appName] = $true
                    continue
                }
            }
            catch {
                Write-ColorOutput "Falling back to scoop for $appName" 'Yellow'
            }
            Write-ColorOutput "Installing $appName via winget..." 'Yellow'
            winget install --id $app.wingetId --silent --accept-package-agreements
            if ($?) {
                $script:installedTools[$appName] = $true
                Write-ColorOutput "$appName installed successfully via winget" 'Green'
                continue
            }
        }
        if (-not $app.cmd) {
            if (Confirm-Installation $appName $appPath) {
                Write-ColorOutput "Updating $appName..." 'Yellow'
                scoop update $appName
                $script:installedTools[$appName] = $true
            }
            else {
                Write-ColorOutput "Installing $appName..." 'Yellow'
                try {
                    scoop install $appName
                    $script:installedTools[$appName] = $true
                }
                catch {
                    Write-ColorOutput "Failed to install $($appName): $_" 'Red'
                    $script:failed += $appName
                }
            }
            continue
        }
        if (Confirm-Installation $appName $appPath $app.cmd $app.args) {
            Write-ColorOutput "Updating $appName..." 'Yellow'
            try {
                scoop update $appName
                $script:installedTools[$appName] = $true
            }
            catch {
                Write-ColorOutput "Failed to update $($appName): $_" 'Yellow'
            }
        }
        else {
            Write-ColorOutput "Installing $appName..." 'Yellow'
            try {
                scoop install $appName
                if (Test-Path $appPath) {
                    $script:installedTools[$appName] = $true
                    Write-ColorOutput "$appName installed successfully" 'Green'
                }
                else {
                    Write-ColorOutput "Installation completed but $appName not found at expected path" 'Yellow'
                    $script:skipped += $appName
                }
            }
            catch {
                Write-ColorOutput "Failed to install $($appName): $_" 'Red'
                $script:failed += $appName
            }
        }
    }

    # Ensure VS Code is installed and configured
    if (Get-Command code -ErrorAction SilentlyContinue) {
        Write-ColorOutput "`nConfiguring VS Code settings and extensions..." 'Cyan'
        $vsCodeSettingsPath = Join-Path $env:APPDATA "Code\User\settings.json"
        $vsCodeSettingsDir = Split-Path $vsCodeSettingsPath
        if (-not (Test-Path $vsCodeSettingsDir)) {
            New-Item -ItemType Directory -Force -Path $vsCodeSettingsDir | Out-Null
        }
        $defaultSettings = @{
            "editor.fontFamily"                          = "'FiraCode NF', Consolas, 'Courier New', monospace"
            "editor.fontLigatures"                       = $true
            "editor.fontSize"                            = 14
            "editor.wordWrap"                            = "on"
            "editor.formatOnSave"                        = $true
            "editor.minimap.enabled"                     = $true
            "editor.renderWhitespace"                    = "boundary"
            "editor.rulers"                              = @(80, 120)
            "workbench.colorTheme"                       = "Default Dark Modern"
            "terminal.integrated.fontFamily"             = "'FiraCode NF'"
            "terminal.integrated.defaultProfile.windows" = "PowerShell"
            "explorer.confirmDelete"                     = $false
            "files.autoSave"                             = "afterDelay"
            "files.autoSaveDelay"                        = 1000
            "git.autofetch"                              = $true
            "git.confirmSync"                            = $false
            "breadcrumbs.enabled"                        = $true
            "diffEditor.ignoreTrimWhitespace"            = $false
            "editor.suggestSelection"                    = "first"
            "debug.toolBarLocation"                      = "docked"
        }
        if (Test-Path $vsCodeSettingsPath) {
            try {
                $existingSettings = Get-Content $vsCodeSettingsPath | ConvertFrom-Json -AsHashtable
                foreach ($key in $defaultSettings.Keys) {
                    if (-not $existingSettings.ContainsKey($key)) {
                        $existingSettings[$key] = $defaultSettings[$key]
                    }
                }
                $existingSettings | ConvertTo-Json -Depth 10 | Set-Content $vsCodeSettingsPath
                Write-ColorOutput "VS Code settings updated!" 'Green'
            }
            catch {
                Write-ColorOutput "Error updating VS Code settings: $_" 'Red'
                $defaultSettings | ConvertTo-Json -Depth 10 | Set-Content $vsCodeSettingsPath
            }
        }
        else {
            $defaultSettings | ConvertTo-Json -Depth 10 | Set-Content $vsCodeSettingsPath
            Write-ColorOutput "Created VS Code settings file with default settings" 'Green'
        }
        $essentialExtensions = @(
            "ms-vscode.powershell", "ms-dotnettools.csharp", "ms-python.python",
            "ms-python.vscode-pylance", "ms-azuretools.vscode-docker", "dbaeumer.vscode-eslint",
            "esbenp.prettier-vscode", "golang.go", "redhat.java", "vscjava.vscode-java-debug",
            "rust-lang.rust-analyzer", "ms-vscode-remote.remote-wsl", "ms-vscode-remote.remote-containers",
            "github.copilot", "github.vscode-pull-request-github"
        )
        Write-ColorOutput "Installing essential VS Code extensions..." 'Yellow'
        foreach ($extension in $essentialExtensions) {
            Write-ColorOutput "Installing extension: $extension" 'Gray'
            code --install-extension $extension --force
        }
    }
    else {
        Write-ColorOutput "VS Code not found in PATH. Skipping configuration." 'Yellow'
        $script:skipped += 'vscode-config'
    }

    # Add development tools to PATH
    Write-ColorOutput "`nConfiguring PATH environment variables..." 'Cyan'
    $paths = @(
        @{Path = (Join-Path $env:USERPROFILE "scoop\apps\git\current\cmd"); Scope = 'Machine'; Tool = 'git' }
        @{Path = (Join-Path $env:USERPROFILE "scoop\apps\python\current"); Scope = 'Machine'; Tool = 'python' }
        @{Path = (Join-Path $env:USERPROFILE "scoop\apps\python\current\Scripts"); Scope = 'Machine'; Tool = 'python-scripts' }
        @{Path = (Join-Path $env:USERPROFILE "scoop\apps\nodejs-lts\current"); Scope = 'Machine'; Tool = 'nodejs' }
        @{Path = (Join-Path $env:USERPROFILE "scoop\apps\go\current\bin"); Scope = 'Machine'; Tool = 'go' }
        @{Path = (Join-Path $env:USERPROFILE "scoop\apps\ruby\current\bin"); Scope = 'Machine'; Tool = 'ruby' }
        @{Path = (Join-Path $env:USERPROFILE "scoop\apps\rust\current\bin"); Scope = 'Machine'; Tool = 'rust' }
        @{Path = (Join-Path $env:USERPROFILE "scoop\apps\java\current\bin"); Scope = 'Machine'; Tool = 'java' }
        @{Path = (Join-Path $env:USERPROFILE "scoop\shims"); Scope = 'User'; Tool = 'scoop-shims' }
        @{Path = (Join-Path $env:USERPROFILE ".cargo\bin"); Scope = 'User'; Tool = 'cargo-bin' }
        @{Path = (Join-Path $env:USERPROFILE "go\bin"); Scope = 'User'; Tool = 'go-bin' }
    )
    foreach ($pathInfo in $paths) {
        if (Test-Path $pathInfo.Path) {
            if (Add-ToPath -PathToAdd $pathInfo.Path -Scope $pathInfo.Scope) {
                $script:installedTools["path-$($pathInfo.Tool)"] = $true
            }
        }
        else {
            Write-ColorOutput "Path not found, skipping: $($pathInfo.Path)" 'Yellow'
            $script:skipped += "path-$($pathInfo.Tool)"
        }
    }

    # Install Node.js global packages
    if (Test-ToolVersion 'node' -Silent) {
        Write-ColorOutput "`nInstalling/Updating Node.js global packages..." 'Cyan'
        $nodePackages = @(
            'pnpm', 'yarn', 'typescript', 'ts-node', 'nodemon', 'npm-check-updates',
            '@angular/cli', 'create-react-app', '@vue/cli', 'next', 'nx',
            'eslint', 'prettier', 'serve', 'vercel', 'netlify-cli', 'firebase-tools',
            'webpack-cli', 'vite', 'turbo', 'jest', 'cypress'
        )
        foreach ($package in $nodePackages) {
            if (Test-ToolVersion $package -Silent) {
                Write-ColorOutput "Updating $package..." 'Yellow'
                npm update -g $package
            }
            else {
                Write-ColorOutput "Installing $package..." 'Yellow'
                npm install -g $package
            }
        }
    }

    # Install Python packages
    if (Test-ToolVersion 'python' -Silent) {
        Write-ColorOutput "`nInstalling/Updating Python packages..." 'Cyan'
        $pythonPackages = @(
            'pip', 'virtualenv', 'pipenv', 'poetry', 'black', 'pylint', 'mypy', 'flake8',
            'pytest', 'pytest-cov', 'pytest-asyncio', 'django', 'flask', 'fastapi', 'uvicorn',
            'jupyter', 'pandas', 'numpy', 'matplotlib', 'seaborn', 'requests', 'httpx',
            'aiohttp', 'beautifulsoup4', 'rich'
        )
        foreach ($package in $pythonPackages) {
            if (python -m pip show $package 2>$null) {
                Write-ColorOutput "Updating $package..." 'Yellow'
                python -m pip install --upgrade $package
            }
            else {
                Write-ColorOutput "Installing $package..." 'Yellow'
                python -m pip install $package
            }
        }
    }

    # Create development directories
    $devFolders = @('Projects', 'Workspace', 'Development', 'GitHub', '.ssh', '.config', '.docker', 'Downloads\Development')
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

    # Create PowerShell profile
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }
    Add-Content $PROFILE @"
# Initialize Oh My Posh
oh-my-posh init pwsh --config "`$env:POSH_THEMES_PATH\agnoster.omp.json" | Invoke-Expression

# Custom aliases
Set-Alias -Name g -Value git
Set-Alias -Name py -Value python
Set-Alias -Name code -Value code-insiders
Set-Alias -Name k -Value kubectl

# Auto-update function
function Update-DevEnv {
    Write-Host "Updating development environment..." -ForegroundColor Cyan
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
    foreach ($var in $envVars.GetEnumerator()) {
        $currentValue = [System.Environment]::GetEnvironmentVariable($var.Key, 'Machine')
        if ($currentValue -ne $var.Value) {
            [System.Environment]::SetEnvironmentVariable($var.Key, $var.Value, 'Machine')
            Write-ColorOutput "Updated environment variable: $($var.Key)" 'Yellow'
        }
        else {
            Write-ColorOutput "Environment variable $($var.Key) already set correctly" 'Green'
        }
    }

    # Verify PATH configurations
    Write-ColorOutput "`nVerifying PATH configurations..." 'Cyan'
    $missingPaths = Test-AllPaths
    if ($missingPaths.Machine.Count -gt 0 -or $missingPaths.User.Count -gt 0) {
        Write-ColorOutput "Attempting to fix missing PATH entries..." 'Yellow'
        foreach ($path in $missingPaths.Machine) {
            if (Test-Path $path) {
                Add-ToPath -PathToAdd $path -Scope 'Machine'
            }
        }
        foreach ($path in $missingPaths.User) {
            if (Test-Path $path) {
                Add-ToPath -PathToAdd $path -Scope 'User'
            }
        }
    }

    # Create scheduled task for auto-updates
    $taskName = "DevelopmentEnvironmentUpdate"
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command Update-DevEnv"
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9AM
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-ColorOutput "Updating scheduled task..." 'Yellow'
        Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings
    }
    else {
        Write-ColorOutput "Creating scheduled task..." 'Yellow'
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings
    }

    # Final validation
    Write-ColorOutput "Performing final validation..." 'Cyan'
    $validationResults = @()
    $toolsToValidate = @('git', 'node', 'python', 'docker', 'code', 'kubectl')
    foreach ($tool in $toolsToValidate) {
        if (Test-ToolVersion $tool -Silent) {
            $validationResults += "${tool}: OK"
        }
        else {
            $validationResults += "${tool}: Not found or not working"
        }
    }
    Write-ColorOutput "`nInstallation Status:" 'Cyan'
    $validationResults | ForEach-Object { Write-ColorOutput $_ 'White' }
    if ($script:failed.Count -gt 0) {
        Write-ColorOutput "Failed installations: $($script:failed -join ', ')" 'Red'
    }
    if ($script:skipped.Count -gt 0) {
        Write-ColorOutput "Skipped items: $($script:skipped -join ', ')" 'Yellow'
    }
    Write-ColorOutput "Setup completed!" 'Green'
    Stop-Transcript
}
catch {
    Write-ColorOutput "An unexpected error occurred: $_" 'Red'
    Stop-Transcript
    exit 1
}
