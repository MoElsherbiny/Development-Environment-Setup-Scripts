# **Development Environment Setup Script Guide**

This guide provides step-by-step instructions for setting up a development environment on **Windows**, **macOS**, and **Linux** using the provided scripts. It includes detailed steps for running the scripts, troubleshooting common issues, and customizing the setup for your needs.

---

## **Table of Contents**

1. **Overview**
2. **Features**
3. **Requirements**
4. **Installation**
   - Windows
   - macOS
   - Linux
5. **Configuration**
6. **Customization**
7. **Maintenance**
8. **Troubleshooting**
9. **Logging**
10. **Uninstallation**
11. **Contributing**
12. **Disclaimer**

---

## **1. Overview**

This script automates the setup and configuration of a comprehensive development environment. It installs essential tools, programming languages, frameworks, and utilities while configuring system settings, environment variables, and development-related applications.

---

## **2. Features**

- **Package Management**:
  - Windows: Scoop and Winget
  - macOS: Homebrew
  - Linux: apt (Debian/Ubuntu) or dnf (Fedora/RHEL)
- **Tool Installation**:
  - Version control (Git)
  - Programming languages (Node.js, Python, Go, Rust, Java, etc.)
  - Development tools (Docker, Kubernetes, Terraform, etc.)
  - IDEs and editors (VS Code, Terminal)
  - Database tools (MySQL, PostgreSQL, MongoDB, Redis)
  - Cloud CLI tools (AWS, Azure, GCP)
- **Environment Configuration**:
  - Sets up PATH environment variables
  - Configures Git settings
  - Creates development directory structure
  - Configures VS Code with extensions and settings
  - Configures terminal (Windows Terminal, iTerm2, etc.)
- **Automation**:
  - Scheduled updates (cron jobs or Task Scheduler)
  - Self-updating functionality
  - Provides shortcut commands for common development tasks

---

## **3. Requirements**

- **Windows**:
  - Windows 10/11
  - PowerShell 5.1 or later
  - Administrator privileges
- **macOS**:
  - macOS 10.15 (Catalina) or later
  - Homebrew (installed by the script if missing)
- **Linux**:
  - Ubuntu/Debian or Fedora/RHEL
  - sudo privileges
- **All Platforms**:
  - Internet connection

---

## **4. Installation**

### **Windows**

1. **Open PowerShell as Administrator**:

   - Press `Win + X` and select **Windows PowerShell (Admin)** or **Terminal (Admin)**.
   - Alternatively, search for "PowerShell" in the Start menu, right-click it, and select **Run as Administrator**.

2. **Enable Script Execution (if needed)**:

   - By default, PowerShell restricts script execution for security reasons. If you encounter an error like:
     ```
     .\WindowsDevEnv-Setup.ps1 cannot be loaded because running scripts is disabled on this system.
     ```
   - Run the following command to allow script execution:
     ```powershell
     Set-ExecutionPolicy RemoteSigned -Scope Process -Force
     ```

3. **Navigate to the Script Directory**:

   - Use the `cd` command to navigate to the folder where the script is located. For example:
     ```powershell
     cd C:\Path\To\Script
     ```

4. **Execute the Script**:
   - Run the script by typing:
     ```powershell
     .\WindowsDevEnv-Setup.ps1
     ```

---

### **macOS**

1. **Open Terminal**:

   - Launch Terminal from Applications > Utilities or search for it using Spotlight (`Cmd + Space`).

2. **Download and Run the Script**:

   - Download the script and make it executable:
     ```bash
     curl -O https://raw.githubusercontent.com/your-repo/dev-setup.sh
     chmod +x dev-setup.sh
     ```

3. **Run the Script**:
   - Execute the script:
     ```bash
     ./dev-setup.sh
     ```

---

### **Linux**

1. **Open Terminal**:

   - Launch Terminal from your applications menu or press `Ctrl + Alt + T`.

2. **Download and Run the Script**:

   - Download the script and make it executable:
     ```bash
     curl -O https://raw.githubusercontent.com/your-repo/dev-setup.sh
     chmod +x dev-setup.sh
     ```

3. **Run the Script**:
   - Execute the script with sudo:
     ```bash
     sudo ./dev-setup.sh
     ```

---

## **5. Configuration**

The script automatically configures:

- **VS Code**:
  - Installs essential extensions
  - Sets up default settings
  - Configures font and theme
- **Terminal**:
  - macOS: Configures iTerm2 with Oh My Zsh and Powerlevel10k
  - Linux: Configures Bash or Zsh with custom aliases
  - Windows: Configures Windows Terminal with FiraCode NF font
- **Git**:
  - Sets core configurations
  - Configures credential helper
- **Environment Variables**:
  - Sets up paths for Python, Node.js, Go, Java, etc.
- **Shell Profile**:
  - Creates useful aliases
  - Adds development shortcuts
  - Configures Oh My Posh (Windows) or Oh My Zsh (macOS/Linux)

---

## **6. Customization**

### **VS Code Extensions**

Create an `extensions.txt` file in the same directory as the script to add custom VS Code extensions. Each line should contain one extension ID.

Example `extensions.txt`:

```
ms-vscode.csharp
ms-python.python
redhat.vscode-yaml
```

### **Environment Variables**

The script sets up common environment variables. To add custom variables, modify the `$envVars` hashtable in the script.

---

## **7. Maintenance**

The script includes automated maintenance features:

- **Scheduled Updates**:
  - Windows: Task Scheduler (every Monday at 9 AM)
  - macOS/Linux: Cron job (every Monday at 9 AM)
- **Manual Update**:
  - Run `update_dev_env` in your terminal to manually update all tools.
- **Self-Healing**:
  - Automatically fixes common PATH issues.

---

## **8. Troubleshooting**

### **Common Issues**

1. **Script Not Found**:

   - Ensure the script is in the current directory or provide the full path to the script.

2. **Permission Denied**:

   - Ensure you are running the script with administrator or sudo privileges.

3. **Internet Connectivity Problems**:

   - Check your network connection.
   - If using a proxy, configure your terminal to use it.

4. **PATH Configuration Problems**:

   - Verify that the script has added the correct paths to your system PATH.

5. **Review Logs**:
   - Logs are saved to:
     - Windows: `%TEMP%\dev-setup-<timestamp>.log`
     - macOS/Linux: `/tmp/dev-setup-<timestamp>.log`

---

## **9. Logging**

The script creates detailed logs for troubleshooting:

- **Windows**:
  ```
  %TEMP%\dev-setup-<timestamp>.log
  ```
- **macOS/Linux**:
  ```
  /tmp/dev-setup-<timestamp>.log
  ```

---

## **10. Uninstallation**

To remove installed tools:

1. **Windows**:

   - Use Scoop to uninstall packages:
     ```powershell
     scoop uninstall <package>
     ```
   - Use Winget to remove applications:
     ```powershell
     winget uninstall <package>
     ```

2. **macOS**:

   - Use Homebrew to uninstall packages:
     ```bash
     brew uninstall <package>
     ```

3. **Linux**:

   - Use apt or dnf to uninstall packages:
     ```bash
     sudo apt remove <package>  # Debian/Ubuntu
     sudo dnf remove <package>  # Fedora/RHEL
     ```

4. **All Platforms**:
   - Manually remove environment variables and PATH entries.

---

## **11. Contributing**

Contributions are welcome! Please open an issue or pull request for any improvements or bug fixes.

---

## **12. Disclaimer**

This script modifies system settings and installs software. Use with caution and review the code before running. The author is not responsible for any system instability or data loss that may occur.

---

**Note**: This script is designed for development environments. Some configurations may not be suitable for production systems. Always review and test changes in a safe environment before deploying to production systems.

---

Created with ❤ by Mohamed ELsherbiny

---

## **Additional Sections**

### **Granting PowerShell Full Control via Registry Editor**

In some cases, you may need to grant PowerShell full control over your system to ensure scripts run without restrictions. This can be particularly useful if you encounter persistent permission issues or if your organization has strict security policies.

---

### **Steps to Grant PowerShell Full Control**

#### **Step 1: Open the Registry Editor**

- Press `Win + R` to open the Run dialog.
- Type `regedit` and press `Enter`.
- Click **Yes** if prompted by User Account Control (UAC).

#### **Step 2: Navigate to the PowerShell Execution Policies Key**

- In the Registry Editor, navigate to the following path:
  ```
  HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell
  ```
- If the `PowerShell` key does not exist, create it:
  - Right-click on the `Windows` key.
  - Select **New > Key** and name it `PowerShell`.

#### **Step 3: Create or Modify the `EnableScripts` Value**

- Inside the `PowerShell` key, check if a value named `EnableScripts` exists:
  - If it exists, double-click it and set its value to `1`.
  - If it does not exist:
    - Right-click in the right-hand pane.
    - Select **New > DWORD (32-bit) Value**.
    - Name the new value `EnableScripts`.
    - Double-click `EnableScripts` and set its value to `1`.

#### **Step 4: Grant Full Control to PowerShell**

- Navigate to the following key:
  ```
  HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
  ```
- Right-click the `Environment` key and select **Permissions**.
- In the Permissions window:
  - Click **Add**.
  - In the "Enter the object names to select" field, type `SYSTEM` and click **Check Names**.
  - Click **OK**.
  - In the Permissions window, select `SYSTEM` and check the box for **Full Control** under "Allow".
  - Click **Apply** and then **OK**.

#### **Step 5: Restart Your Computer**

- Close the Registry Editor and restart your computer to apply the changes.

---

### **Verify PowerShell Full Control**

1. **Open PowerShell as Administrator**:

   - Press `Win + X` and select **Windows PowerShell (Admin)** or **Terminal (Admin)**.

2. **Check Execution Policy**:

   - Run the following command to check the current execution policy:
     ```powershell
     Get-ExecutionPolicy -List
     ```
   - Ensure the policies are set to allow script execution. For example:
     - `MachinePolicy` and `UserPolicy` should be set to `Unrestricted` or `RemoteSigned`.

3. **Test Script Execution**:
   - Try running a simple script to verify that PowerShell has full control. For example:
     ```powershell
     .\WindowsDevEnv-Setup.ps1
     ```

---

### **Reverting Changes**

If you encounter issues or no longer need these settings, you can revert the changes:

1. **Remove the `EnableScripts` Value**:

   - Navigate back to:
     ```
     HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell
     ```
   - Delete the `EnableScripts` value.

2. **Restore Default Permissions**:

   - Navigate to:
     ```
     HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
     ```
   - Right-click the `Environment` key, select **Permissions**, and remove the `SYSTEM` entry or restore default permissions.

3. **Reset Execution Policy**:
   - Open PowerShell as Administrator and run:
     ```powershell
     Set-ExecutionPolicy Restricted -Scope LocalMachine -Force
     ```

---

## **Important Security Considerations**

- Granting full control to PowerShell can expose your system to potential security risks. Only use this method if absolutely necessary and in a trusted environment.
- Always run scripts from trusted sources and review their contents before execution.
- Consider using less permissive execution policies (e.g., `RemoteSigned`) for daily use.

---

By following this guide, you can successfully run the `WindowsDevEnv-Setup.ps1` script and grant PowerShell full control if needed. If you encounter any issues, refer to the troubleshooting steps or consult the logs for detailed error messages.

Created with Mohamed Elsherbiny ❤
