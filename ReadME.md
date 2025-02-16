````markdown
# Cross-Platform Development Environment Setup

Automated setup scripts for configuring comprehensive development environments on Windows and Unix-based systems (macOS/Linux). Features smart installation, PATH validation, and automatic updates.

## 🔄 Version 2.1.0

- Added Unix (macOS/Linux) support
- Enhanced PATH verification
- Improved version checking
- Auto-fix capabilities
- Cross-platform compatibility

## 🚀 Quick Installation

### Windows

```powershell
# Download and run as Administrator
Invoke-WebRequest -Uri "YOUR_SCRIPT_URL/setup.ps1" -OutFile "setup.ps1"
Set-ExecutionPolicy Bypass -Scope Process -Force
.\setup.ps1
```
````

### macOS/Linux

```bash
# Download and run
curl -O "YOUR_SCRIPT_URL/setup.sh"
chmod +x setup.sh
# macOS: ./setup.sh
# Linux: sudo ./setup.sh
```

## ✨ Key Features

- **Smart Installation**: Checks existing tools and versions
- **PATH Management**: Validates and fixes PATH entries
- **Auto-Updates**: Weekly scheduled maintenance
- **Cross-Platform**: Windows and Unix compatibility
- **Development Tools**: 40+ essential tools
- **Shell Configuration**: PowerShell/Bash/Zsh profiles

## 🛠 Included Tools

| Category             | Windows                   | Unix                      |
| -------------------- | ------------------------- | ------------------------- |
| **Package Managers** | Scoop                     | Homebrew/apt/dnf          |
| **Version Control**  | Git, GitHub CLI           | Git, GitHub CLI           |
| **Containers**       | Docker, K8s tools         | Docker, K8s tools         |
| **Languages**        | Node.js, Python, Go, etc. | Node.js, Python, Go, etc. |
| **Cloud Tools**      | AWS, Azure, Terraform     | AWS, Azure, Terraform     |
| **Databases**        | MySQL, PostgreSQL, etc.   | MySQL, PostgreSQL, etc.   |
| **Editors**          | VS Code + extensions      | VS Code + extensions      |
| **Terminal**         | Windows Terminal          | iTerm2/default            |
| **Additional**       | PowerToys, etc.           | Platform-specific tools   |

## 🔍 Validation Features

### PATH Verification

```powershell
# Windows
Test-AllPaths
Test-ToolVersion 'node'

# Unix
verify_all_paths
test_tool_version node
```

### Environment Variables

| Windows     | Unix        |
| ----------- | ----------- |
| PYTHON_HOME | PYTHON_HOME |
| NODE_PATH   | NODE_PATH   |
| GOPATH      | GOPATH      |
| JAVA_HOME   | JAVA_HOME   |
| MAVEN_HOME  | MAVEN_HOME  |

## 📂 Directory Structure

```plaintext
$HOME/
├── Development/       # Development resources
├── GitHub/            # Git repositories
├── .ssh/              # SSH configurations
├── .config/           # Tool configurations
└── .docker/           # Docker configurations
```

## 🔄 Update System

### Automatic

- **Windows**: Scheduled Task (Monday, 9 AM)
- **Unix**: Cron Job (Monday, 9 AM)

### Manual

```powershell
# Windows
Update-DevEnv

# Unix
update_dev_env
```

## ⚡ Common Aliases

### Development

```bash
g       -> git
py      -> python/python3
k       -> kubectl
code    -> VSCode
```

### Docker

```bash
dps     -> docker ps
dcp     -> docker-compose up
dcpd    -> docker-compose up -d
dcd     -> docker-compose down
```

### Navigation

```bash
cdp     -> cd ~/Projects
cdw     -> cd ~/Workspace
cdg     -> cd ~/GitHub
```

## 🔧 Troubleshooting

1. **Permission Issues**

   - Windows: Run as Administrator
   - Unix: Use sudo when required

2. **PATH Problems**

   - Windows: Run `Test-AllPaths`
   - Unix: Run `verify_all_paths`

3. **Tool Versions**
   - Windows: `Test-ToolVersion tool_name`
   - Unix: `test_tool_version tool_name`

## 🔒 Security

- Administrator/sudo required
- HTTPS downloads only
- Checksum verification
- Official sources only
- No data collection

## 📦 Requirements

### Windows

- Windows 10/11
- PowerShell 5.1+
- Administrator access

### Unix

- macOS 10.15+ or modern Linux
- Bash/Zsh shell
- Sudo privileges (Linux)

---

Created with ❤ by Mohamed ELsherbiny

```

```
