# Development Environment Setup Scripts

A comprehensive collection of scripts to automate the setup of development environments across Windows, macOS, and Linux systems. These scripts install and configure essential development tools, set up environment variables, and establish an auto-update system to keep your development environment current.

## 🚀 Features

### Core Functionality

- Automated installation of development tools and packages
- Weekly automatic updates
- Custom shell configurations and aliases
- Consistent development environment across platforms
- Environment variable management
- Development directory structure setup

### Included Tools & Technologies

#### 📦 Package Managers

- Windows: Scoop
- macOS: Homebrew
- Linux: apt/dnf

#### 💻 Programming Languages & Runtimes

- Node.js (with npm, pnpm, yarn)
- Python (with pip, virtualenv, pipenv, poetry)
- Go
- Rust
- Ruby
- GCC/Build Tools

#### 🛠 Development Tools

- Git
- Visual Studio Code
- Docker & Docker Compose
- Kubernetes Tools
- Terminal Emulators (Windows Terminal/iTerm2)
- PowerToys (Windows)

#### ☁️ Cloud Tools

- AWS CLI
- Azure CLI
- Terraform
- kubectl

#### 🌐 Browsers

- Google Chrome
- Firefox Developer Edition
- Microsoft Edge (Windows)

#### 📱 Additional Tools

- Postman
- GitHub CLI
- Development Fonts
- Various CLI utilities

## 📋 Prerequisites

### Windows

- Windows 10/11
- PowerShell 5.1 or higher
- Administrator privileges

### macOS/Linux

- macOS 10.15+ or modern Linux distribution
- Bash or Zsh shell
- Sudo privileges (Linux)

## 🔧 Installation

### Windows Setup

1. Download the script:

```powershell
Invoke-WebRequest -Uri "RAW_SCRIPT_URL" -OutFile "setup.ps1"
```

2. Open PowerShell as Administrator and navigate to the script location

3. Set execution policy and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
Unblock-File -Path .\setup.ps1
.\setup.ps1
```

### macOS/Linux Setup

1. Download the script:

```bash
curl -O "RAW_SCRIPT_URL"
```

2. Make it executable:

```bash
chmod +x setup.sh
```

3. Run the script:

- macOS:

```bash
./setup.sh
```

- Linux:

```bash
sudo ./setup.sh
```

## 🔄 Update System

### Automatic Updates

- Windows: Scheduled task runs every Monday at 9 AM
- Unix: Cron job runs every Monday at 9 AM

### Manual Updates

#### Windows

```powershell
Update-DevEnv
```

#### macOS/Linux

```bash
update_dev_env
```

## 📁 Directory Structure

The scripts create the following directory structure in your home folder:

```
$HOME/
├── Projects/
├── Workspace/
├── Development/
├── GitHub/
├── .ssh/
└── .config/
```

## ⚡ Aliases and Functions

### Windows PowerShell Aliases

```powershell
g       -> git
py      -> python
code    -> code-insiders
k       -> kubectl
```

### Unix Shell Aliases

```bash
g       -> git
py      -> python3
dps     -> docker ps
dcp     -> docker-compose up
dcpd    -> docker-compose up -d
dcd     -> docker-compose down
k       -> kubectl
tf      -> terraform
```

### Git Aliases (All Platforms)

```bash
gs      -> git status
gp      -> git pull
gps     -> git push
gc      -> git checkout
gb      -> git branch
```

### Directory Shortcuts (All Platforms)

```bash
cdp     -> cd ~/Projects
cdw     -> cd ~/Workspace
cdg     -> cd ~/GitHub
```

## 🔐 Security Notes

- Windows script requires Administrator privileges
- Linux script requires sudo access
- All scripts download from trusted sources only
- No sensitive data is collected or transmitted

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## ⚠️ Known Issues

1. Windows:

   - Some applications might require manual intervention during installation
   - Windows Terminal settings might need manual adjustment

2. macOS/Linux:
   - Some packages might require additional dependencies based on the OS version
   - Custom fonts might need manual installation on some Linux distributions

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Scoop package manager for Windows
- Homebrew package manager for macOS
- Various open-source tools and their maintainers

## 📞 Support

If you encounter any issues or have questions:

1. Check the Known Issues section
2. Create an issue in the repository
3. Provide detailed information about your system and the error

## 🔄 Version History

### v1.0.0 (2025-02-15)

- Initial release
- Support for Windows, macOS, and Linux
- Automatic update system
- Basic development environment setup

### v1.1.0 (Coming Soon)

- Additional language support
- More cloud provider tools
- Enhanced error handling
- Custom configuration options

## 🚀 Quick Start Guide

1. Choose the appropriate script for your operating system
2. Run the script with appropriate privileges
3. Restart your terminal after installation
4. Verify installation with built-in check commands
5. Start using the new development environment

## ⚙️ Configuration

### Windows

- PowerShell profile: `$PROFILE`
- Scoop config: `$env:USERPROFILE\scoop\config.json`
- Git config: `$env:USERPROFILE\.gitconfig`

### macOS/Linux

- Shell config: `~/.bashrc` or `~/.zshrc`
- Git config: `~/.gitconfig`
- Environment variables: `/etc/environment` or shell config

## 🔍 Troubleshooting

### Common Issues

1. Permission Errors

   - Windows: Ensure you're running as Administrator
   - Unix: Use sudo when required

2. Path Issues

   - Restart terminal after installation
   - Verify environment variables

3. Package Installation Failures
   - Check internet connection
   - Verify package manager is working
   - Look for conflicting installations

### Verification Commands

Test your installation with these commands:

```bash
git --version
node --version
python --version
docker --version
kubectl version
terraform --version
```
