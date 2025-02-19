# Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script version and timestamp
$SCRIPT_VERSION = "4.0.0"
$SCRIPT_TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$SCRIPT_LOG_PATH = Join-Path $env:TEMP "dev-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Start transcript logging
Start-Transcript -Path $SCRIPT_LOG_PATH -Append

# Function to write colored output with logging
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White',
        [switch]$NoNewLine
    )
    Write-Host $Message -ForegroundColor $Color -NoNewLine:$NoNewLine
    Add-Content -Path $SCRIPT_LOG_PATH -Value $Message
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

    # Verify the path actually exists
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
    # First check if we can execute the command
    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        if (Test-ToolVersion -Command $CommandName -VersionArg $VersionArg -Silent) {
            Write-ColorOutput "$Tool is already installed and working" 'Green'
            return $true
        }
    }

    # If command check fails, check the install path
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

    # Normalize path by removing trailing backslash
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
        # Update Scoop and all apps
        Write-ColorOutput "Updating Scoop and its packages..." 'Yellow'
        try {
            scoop update
            scoop update *
        }
        catch {
            $updateErrors += "Scoop update failed: $_"
        }

        # Update npm and global packages
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

        # Update pnpm
        if (Test-ToolVersion 'pnpm' -Silent) {
            Write-ColorOutput "Updating pnpm..." 'Yellow'
            try {
                npm install -g pnpm@latest
            }
            catch {
                $updateErrors += "pnpm update failed: $_"
            }
        }

        # Update Python and pip packages
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

        # Update winget packages if available
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

# Check if running as Administrator
$adminCheck = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$adminRole = [System.Security.Principal.WindowsPrincipal]::new($adminCheck)
if (-not $adminRole.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-ColorOutput "Error: Please run this script as Administrator!" 'Red'
    Write-ColorOutput "Right-click on PowerShell and select 'Run as Administrator', then run this script again." 'Yellow'
    Stop-Transcript
    exit 1
}

# Initialize tracking variables
$script:installedTools = @{}
$script:failed = @()
$script:skipped = @()

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

# Install Scoop (Windows package manager)
try {
    if (Test-ToolVersion 'scoop' -Silent) {
        $script:installedTools['scoop'] = $true
        Write-ColorOutput "Scoop is already installed, checking for updates..." 'Green'
        scoop update
    }
    else {
        Write-ColorOutput "Installing Scoop..." 'Yellow'
        try {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

            # Set Scoop path
            $env:SCOOP = Join-Path $env:USERPROFILE "scoop"
            [System.Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
            $script:installedTools['scoop'] = $true
        }
        catch {
            Write-ColorOutput "Failed to install Scoop: $_" 'Red'
            $script:failed += 'scoop'

            # Try installing with PowerShell 5 method
            Write-ColorOutput "Trying alternative installation method..." 'Yellow'
            try {
                iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
                $script:installedTools['scoop'] = $true
                Write-ColorOutput "Scoop installed successfully using alternative method" 'Green'
            }
            catch {
                Write-ColorOutput "All Scoop installation methods failed" 'Red'
                $script:failed += 'scoop-alternative'
                Stop-Transcript
                exit 1  # Scoop is critical, exit if it fails
            }
        }
    }

    # Add Scoop buckets
    if ($script:installedTools['scoop']) {
        Write-ColorOutput "Adding Scoop buckets..." 'Yellow'
        @('extras', 'versions', 'nerd-fonts', 'java', 'main') | ForEach-Object {
            scoop bucket add $_ 2>$null
        }
    }
}
catch {
    Write-ColorOutput "Error setting up Scoop: $_" 'Red'
    Stop-Transcript
    exit 1  # Scoop is critical, exit if it fails
}

# Add Scoop to PATH
$scoopShimsPath = Join-Path $env:USERPROFILE "scoop\shims"
Add-ToPath -PathToAdd $scoopShimsPath -Scope 'User'

# Try to check/install winget if it's not present
if (-not (Test-ToolVersion 'winget' -Silent)) {
    Write-ColorOutput "Winget not found. Checking Microsoft Store for App Installer..." 'Yellow'
    try {
        Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1" -Wait
        Write-ColorOutput "Please install App Installer from the Microsoft Store" 'Yellow'
        Write-ColorOutput "Press Enter once installation is complete..." 'Yellow'
        Read-Host | Out-Null

        if (Test-ToolVersion 'winget' -Silent) {
            Write-ColorOutput "Winget installed successfully!" 'Green'
            $script:installedTools['winget'] = $true
        }
        else {
            Write-ColorOutput "Winget installation not detected" 'Yellow'
            $script:skipped += 'winget'
        }
    }
    catch {
        Write-ColorOutput "Failed to launch Microsoft Store for winget installation: $_" 'Red'
        $script:skipped += 'winget'
    }
}
else {
    $script:installedTools['winget'] = $true
    Write-ColorOutput "Winget is already installed" 'Green'
}

# Install essential tools with Scoop
Write-ColorOutput "`nInstalling/Updating essential development tools..." 'Cyan'
$scoopApps = @(
    # Development Tools
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

    # Programming Languages
    @{name = 'ruby'; cmd = 'ruby'; args = '--version' }
    @{name = 'go'; cmd = 'go'; args = 'version' }
    @{name = 'rust'; cmd = 'rustc'; args = '--version' }
    @{name = 'gcc'; cmd = 'gcc'; args = '--version' }
    @{name = 'openjdk17'; cmd = 'java'; args = '--version' }
    @{name = 'kotlin'; cmd = 'kotlin'; args = '-version' }
    @{name = 'dotnet-sdk'; cmd = 'dotnet'; args = '--version' }

    # Cloud & Infrastructure
    @{name = 'kubectl'; cmd = 'kubectl'; args = 'version --client' }
    @{name = 'terraform'; cmd = 'terraform'; args = 'version' }
    @{name = 'aws'; cmd = 'aws'; args = '--version' }
    @{name = 'azure-cli'; cmd = 'az'; args = 'version' }
    @{name = 'github'; cmd = 'gh'; args = '--version' }
    @{name = 'helm'; cmd = 'helm'; args = 'version' }
    @{name = 'k9s'; cmd = 'k9s'; args = 'version' }
    @{name = 'minikube'; cmd = 'minikube'; args = 'version' }

    # Databases
    @{name = 'mysql'; cmd = 'mysql'; args = '--version' }
    @{name = 'postgresql'; cmd = 'psql'; args = '--version' }
    @{name = 'mongodb'; cmd = 'mongo'; args = '--version' }
    @{name = 'redis'; cmd = 'redis-server'; args = '--version' }

    # Browsers - use winget for these if available
    @{name = 'googlechrome'; cmd = ''; args = ''; useWinget = $true; wingetId = 'Google.Chrome' }
    @{name = 'firefox-developer'; cmd = ''; args = ''; useWinget = $true; wingetId = 'Mozilla.Firefox.DeveloperEdition' }
    @{name = 'microsoft-edge-dev'; cmd = ''; args = ''; useWinget = $true; wingetId = 'Microsoft.Edge.Dev' }
    @{name = 'brave'; cmd = ''; args = ''; useWinget = $true; wingetId = 'BraveSoftware.BraveBrowser' }
    # Additional Tools
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

# Define browser extensions
$browserExtensions = @(
    # Frontend Developer Extensions
    @{name = "React Developer Tools"; id = "fmkadmapgofadopljbjfkapdkoienihi" }
    @{name = "Redux DevTools"; id = "lmhkpmbekcpmknklioeibfkpmmfibljd" }
    @{name = "Vue.js Devtools"; id = "nhdogjmejiglipccpnnnanhbledajbpd" }
    @{name = "Angular DevTools"; id = "ienfalfjdbdpebioblfackkekamfmbnh" }
    @{name = "Web Developer"; id = "bfbameneiokkgbdmiekhjnmfkcnldhhm" }
    @{name = "ColorZilla"; id = "bhlhnicpbhignbdhedgjhgdocnmhomnp" }
    @{name = "WhatFont"; id = "jabopobgcpjmedljpbcaablpmlmfcogm" }
    @{name = "CSS Peeper"; id = "mbnbehikldjhnfehhnaidhjhoofhpehk" }
    @{name = "Window Resizer"; id = "kkelicaakdanhinjdeammmilcgefonfh" }
    @{name = "Responsive Viewer"; id = "inmopeiepgfljkpkidclfgbgbmfcennb" }
    @{name = "VisBug"; id = "cdockenadnadldjbbgcallicgledbeoc" }
    @{name = "Lighthouse"; id = "blipmdconlkpinefehnmjammfjpmpbjk" }
    @{name = "WAVE Evaluation Tool"; id = "jbbplnpkjmmeebjpijfedlgcdilocofh" }
    @{name = "uBlock Origin"; id = "cjpalhdlnbpafiamejdnhcphjbkeiagm" }
    @{name = "SVG Export"; id = "naeaaedieihlkmdajjefioajbbdbdjgp" }

    # Backend Developer Extensions
    @{name = "Postman - API Testing"; id = "fhbjgbiflinjbdggehcddcbncdddomop" }
    @{name = "GraphQL Developer Tools"; id = "jhfmdhchcagfkdbgmphnpmpgkghjaffi" }
    @{name = "JSON Formatter"; id = "bcjindcccaagfpapjjmafapmmgkkhgoa" }
    @{name = "JSONView"; id = "chklaanhfefbnpoihckbnefhakgolnmc" }
    @{name = "Cookie Editor"; id = "fngmhnnpilhplaeedifhccceomclgfbg" }
    @{name = "EditThisCookie"; id = "fngmhnnpilhplaeedifhccceomclgfbg" }
    @{name = "Requestly - Modify HTTP Requests"; id = "hafjhmnicikbhmnaffoddblfbigkfkll" }
    @{name = "RESTer - REST API Testing"; id = "faicmgpfiaijcedapokpbdejaodncfpl" }
    @{name = "Security Headers"; id = "gfnanijofpichbemgojmjjnldhgoalkj" }
    @{name = "Wappalyzer"; id = "gppongmhjkpfnbhagpmjfkannfbllamg" }
    @{name = "Octotree - GitHub code tree"; id = "bkhaagjahfmjljalopjnoealnfndnagc" }
    @{name = "GitHub File Icons"; id = "ddgjmnninnfhjbdcnkdgjakjhepkkihh" }
    @{name = "OctoLinker"; id = "inojafojbhdpnehkhhfjalgjjobnhomj" }
)

# Modify the browser installation section
if ($app.useWinget -and $script:installedTools['winget']) {
    Write-ColorOutput "Checking $appName using winget..." 'Yellow'
    if (winget list --id $app.wingetId --exact) {
        Write-ColorOutput "Updating $appName via winget..." 'Yellow'
        winget upgrade --id $app.wingetId --silent
        $script:installedTools[$appName] = $true

        # Install extensions after browser installation/update
        if ($appName -in @('googlechrome', 'microsoft-edge-dev')) {
            Write-ColorOutput "Installing browser extensions for $appName..." 'Yellow'
            foreach ($extension in $browserExtensions) {
                $extensionUrl = "https://chrome.google.com/webstore/detail/$($extension.id)"
                try {
                    Start-Process $extensionUrl
                    Write-ColorOutput "Launched installation for extension: $($extension.name)" 'Gray'
                    Start-Sleep -Seconds 2  # Small delay between extensions
                }
                catch {
                    Write-ColorOutput "Failed to launch extension installation: $($extension.name)" 'Red'
                }
            }
            Write-ColorOutput "Please complete the extension installations in the browser windows" 'Yellow'
            Write-ColorOutput "Press Enter once you have reviewed and installed the extensions..." 'Yellow'
            Read-Host | Out-Null
        }
        continue
    }
    else {
        Write-ColorOutput "Installing $appName via winget..." 'Yellow'
        winget install --id $app.wingetId --silent --accept-package-agreements

        if ($?) {
            $script:installedTools[$appName] = $true
            Write-ColorOutput "$appName installed successfully via winget" 'Green'

            # Install extensions after fresh browser installation
            if ($appName -in @('googlechrome', 'microsoft-edge-dev')) {
                Write-ColorOutput "Installing browser extensions for $appName..." 'Yellow'
                foreach ($extension in $browserExtensions) {
                    $extensionUrl = "https://chrome.google.com/webstore/detail/$($extension.id)"
                    try {
                        Start-Process $extensionUrl
                        Write-ColorOutput "Launched installation for extension: $($extension.name)" 'Gray'
                        Start-Sleep -Seconds 2  # Small delay between extensions
                    }
                    catch {
                        Write-ColorOutput "Failed to launch extension installation: $($extension.name)" 'Red'
                    }
                }
                Write-ColorOutput "Please complete the extension installations in the browser windows" 'Yellow'
                Write-ColorOutput "Press Enter once you have reviewed and installed the extensions..." 'Yellow'
                Read-Host | Out-Null
            }
            continue
        }
        else {
            Write-ColorOutput "Winget installation failed, falling back to scoop" 'Yellow'
        }
    }
}
# Install scoop applications
foreach ($app in $scoopApps) {
    $appName = $app.name
    $appPath = Join-Path $env:USERPROFILE "scoop\apps\$appName\current"

    # For browsers and GUI apps, try to use winget if available
    if ($app.useWinget -and $script:installedTools['winget']) {
        Write-ColorOutput "Checking $appName using winget..." 'Yellow'
        if (winget list --id $app.wingetId --exact) {
            Write-ColorOutput "Updating $appName via winget..." 'Yellow'
            winget upgrade --id $app.wingetId --silent
            $script:installedTools[$appName] = $true
            continue
        }
        else {
            Write-ColorOutput "Installing $appName via winget..." 'Yellow'
            winget install --id $app.wingetId --silent --accept-package-agreements

            if ($?) {
                $script:installedTools[$appName] = $true
                Write-ColorOutput "$appName installed successfully via winget" 'Green'
                continue
            }
            else {
                Write-ColorOutput "Winget installation failed, falling back to scoop" 'Yellow'
            }
        }
    }

    # Skip command validation for font packages and GUI apps
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

    # For command-line tools, check if they exist in PATH
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

            # Verify installation success
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

    # Set up VS Code settings
    $vsCodeSettingsPath = Join-Path $env:APPDATA "Code\User\settings.json"
    $vsCodeSettingsDir = Split-Path $vsCodeSettingsPath

    # Create the VS Code user directory if it doesn't exist
    if (-not (Test-Path $vsCodeSettingsDir)) {
        New-Item -ItemType Directory -Force -Path $vsCodeSettingsDir | Out-Null
    }

    # Create default settings if no source settings available
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

    # Check if settings file exists
    if (Test-Path $vsCodeSettingsPath) {
        # Merge existing settings with defaults
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
            # Create new settings file if existing one can't be parsed
            $defaultSettings | ConvertTo-Json -Depth 10 | Set-Content $vsCodeSettingsPath
        }
    }
    else {
        # Create new settings file
        $defaultSettings | ConvertTo-Json -Depth 10 | Set-Content $vsCodeSettingsPath
        Write-ColorOutput "Created VS Code settings file with default settings" 'Green'
    }

    # Install essential VS Code extensions
    $essentialExtensions = @(
        "ms-vscode.powershell"
        "ms-dotnettools.csharp"
        "ms-python.python"
        "ms-python.vscode-pylance"
        "ms-azuretools.vscode-docker"
        "dbaeumer.vscode-eslint"
        "esbenp.prettier-vscode"
        "golang.go"
        "redhat.java"
        "vscjava.vscode-java-debug"
        "rust-lang.rust-analyzer"
        "ms-vscode-remote.remote-wsl"
        "ms-vscode-remote.remote-containers"
        "github.copilot"
        "github.vscode-pull-request-github"
    )

    Write-ColorOutput "Installing essential VS Code extensions..." 'Yellow'
    foreach ($extension in $essentialExtensions) {
        Write-ColorOutput "Installing extension: $extension" 'Gray'
        code --install-extension $extension --force
    }

    # Look for extensions.txt file in script directory
    $extensionsFile = Join-Path $PSScriptRoot "extensions.txt"
    if (Test-Path $extensionsFile) {
        Write-ColorOutput "Found extensions.txt, installing additional extensions..." 'Yellow'
        Get-Content $extensionsFile | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith('#') } | ForEach-Object {
            $extension = $_.Trim()
            Write-ColorOutput "Installing extension from file: $extension" 'Gray'
            code --install-extension $extension --force
        }
    }

    Write-ColorOutput "VS Code configuration completed!" 'Green'
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

# Install Node.js global packages if Node.js is available
if ($script:installedTools['nodejs-lts'] -or (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-ColorOutput "`nInstalling/Updating Node.js global packages..." 'Cyan'
    $nodePackages = @(
        # Package Managers
        @{name = 'pnpm'; cmd = 'pnpm'; args = '--version' }
        @{name = 'yarn'; cmd = 'yarn'; args = '--version' }

        # Development Tools
        @{name = 'typescript'; cmd = 'tsc'; args = '--version' }
        @{name = 'ts-node'; cmd = 'ts-node'; args = '--version' }
        @{name = 'nodemon'; cmd = 'nodemon'; args = '--version' }
        @{name = 'npm-check-updates'; cmd = 'ncu'; args = '--version' }

        # Frameworks and CLIs
        @{name = '@angular/cli'; cmd = 'ng'; args = 'version' }
        @{name = 'create-react-app'; cmd = 'create-react-app'; args = '--version' }
        @{name = '@vue/cli'; cmd = 'vue'; args = '--version' }
        @{name = 'next'; cmd = 'next'; args = '--version' }
        @{name = 'nx'; cmd = 'nx'; args = 'version' }

        # Code Quality
        @{name = 'eslint'; cmd = 'eslint'; args = '--version' }
        @{name = 'prettier'; cmd = 'prettier'; args = '--version' }

        # Utilities
        @{name = 'serve'; cmd = 'serve'; args = '--version' }
        @{name = 'vercel'; cmd = 'vercel'; args = '--version' }
        @{name = 'netlify-cli'; cmd = 'netlify'; args = '--version' }
        @{name = 'firebase-tools'; cmd = 'firebase'; args = '--version' }

        # Build Tools
        @{name = 'webpack-cli'; cmd = 'webpack-cli'; args = '--version' }
        @{name = 'vite'; cmd = 'vite'; args = '--version' }
        @{name = 'turbo'; cmd = 'turbo'; args = '--version' }

        # Testing
        @{name = 'jest'; cmd = 'jest'; args = '--version' }
        @{name = 'cypress'; cmd = 'cypress'; args = '--version' }
    )

    foreach ($package in $nodePackages) {
        if (Test-ToolVersion $package.cmd -Silent) {
            Write-ColorOutput "Updating $($package.name)..." 'Yellow'
            npm update -g $package.name
        }
        else {
            Write-ColorOutput "Installing $($package.name)..." 'Yellow'
            npm install -g $package.name
        }
    }
}

# Install Python packages if Python is available
if ($script:installedTools['python'] -or (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-ColorOutput "`nInstalling/Updating Python packages..." 'Cyan'
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

# Stop transcript logging
Stop-Transcript
