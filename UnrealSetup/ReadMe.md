# Unreal Engine Development Environment Setup Script

## Overview

This PowerShell script is designed to automate the setup of a comprehensive Unreal Engine development environment on Windows. It handles the installation of all necessary tools, configurations, and dependencies required for Unreal Engine development, including Visual Studio, Epic Games Launcher, artist tools, and development utilities.

## Features

- **Automated Installation**: Installs all necessary tools and dependencies with minimal user input.
- **Customizable Configuration**: Allows users to select which components to install and configure.
- **Compatibility Management**: Ensures that the correct versions of tools are installed based on the selected Unreal Engine version.
- **Environment Setup**: Configures environment variables, Git settings, and PowerShell profiles for optimal development workflow.
- **Backup and Restore**: Creates a backup of the current environment before making changes and allows for easy restoration.
- **Validation**: Performs a final validation to ensure all components are installed and configured correctly.

## Prerequisites

- **Windows 10/11**: The script is designed for Windows operating systems.
- **PowerShell 5.1 or later**: Ensure PowerShell is up to date.
- **Administrator Privileges**: The script requires administrator rights to install software and modify system settings.

## Installation Steps

1. **Download the Script**:

   - Download the `UnrealEngineSetup.ps1` script from the repository.

2. **Run the Script**:

   - Open PowerShell as an administrator.
   - Navigate to the directory where the script is located.
   - Run the script using the following command:
     ```powershell
     .\UnrealEngineSetup.ps1
     ```

3. **Follow the Prompts**:

   - The script will display a welcome banner and guide you through the configuration options.
   - You will be prompted to select which Unreal Engine versions to support, which tools to install, and other configuration settings.

4. **Wait for Completion**:

   - The script will automatically install and configure all selected components. This process may take some time depending on the selected options and your internet connection.

5. **Validation**:
   - After the installation is complete, the script will perform a final validation to ensure everything is set up correctly.

## Configuration Options

The script provides several configuration options that can be customized during the setup process:

- **Unreal Engine Versions**: Select which versions of Unreal Engine to support (e.g., 4.27, 5.0, 5.1, 5.2, 5.3).
- **Visual Studio Installation**: Choose whether to install Visual Studio and select the appropriate workloads.
- **Epic Games Launcher**: Install the Epic Games Launcher, which is required for managing Unreal Engine installations.
- **Development Tools**: Install essential development tools such as Git, Visual Studio Code, Docker, and more.
- **Artist Tools**: Install tools for artists, including Blender, Substance Painter, and Quixel Bridge.
- **Environment Setup**: Configure environment variables, Git settings, and PowerShell profiles.
- **Backup and Restore**: Create a backup of the current environment before making changes.

## Script Components

### Utility Functions

- **Start-Logging**: Initializes logging to a file for troubleshooting and review.
- **Write-ColorOutput**: Outputs colored text to the console with timestamps and logging.
- **Show-WelcomeBanner**: Displays a welcome banner with script information.
- **Get-UserChoices**: Prompts the user for configuration choices.
- **Backup-Environment**: Creates a backup of the current environment.
- **Restore-Environment**: Restores the environment from a backup.
- **Ensure-Chocolatey**: Ensures that Chocolatey (a package manager for Windows) is installed.
- **Test-ToolVersion**: Checks if a tool is installed and retrieves its version.
- **Add-ToPath**: Adds a directory to the system PATH without duplicates.
- **Test-PathExists**: Checks if a path exists in the system PATH.
- **Install-ChocolateyPackages**: Installs Chocolatey packages with progress tracking.
- **Install-PythonPackages**: Installs Python packages with error handling.
- **Test-UnrealEngineInstallation**: Verifies if a specific Unreal Engine installation exists.
- **Test-UnrealEnvironment**: Validates the environment for Unreal Engine development.

### Installation Components

- **Install-VisualStudio**: Installs Visual Studio based on the selected Unreal Engine version.
- **Install-EpicGamesLauncher**: Installs the Epic Games Launcher.
- **Install-DevTools**: Installs development tools such as Git, Visual Studio Code, and Docker.
- **Install-ArtistTools**: Installs artist tools like Blender, Substance Painter, and Quixel Bridge.
- **Install-UnrealPythonDependencies**: Installs Python dependencies required for Unreal Engine.
- **Configure-Git**: Configures Git for Unreal Engine development.
- **Create-DevelopmentDirectories**: Creates recommended directory structures for development.
- **Set-EnvironmentVariables**: Sets environment variables for Unreal Engine development.
- **Create-PowerShellProfile**: Creates a PowerShell profile with Unreal Engine-specific aliases and functions.
- **Validate-Installation**: Performs a final validation of the installation.

## Usage

After running the script and completing the setup, you can start developing with Unreal Engine. The script configures your environment with useful aliases and functions in PowerShell, making it easier to navigate and manage your Unreal Engine projects.

### PowerShell Aliases and Functions

- **ue4**: Navigates to the Unreal Engine 4.27 installation directory.
- **ue5**: Navigates to the Unreal Engine 5.0 installation directory.
- **ue**: Navigates to the latest installed Unreal Engine version.
- **ueprojects**: Navigates to the Unreal Engine projects directory.
- **ueassets**: Navigates to the Unreal Engine assets directory.
- **ueplugins**: Navigates to the Unreal Engine plugins directory.
- **cdp**: Navigates to the Projects directory.
- **cdw**: Navigates to the Workspace directory.
- **cdg**: Navigates to the GitHub directory.
- **gs**: Shortcut for `git status`.
- **gp**: Shortcut for `git pull`.
- **gps**: Shortcut for `git push`.
- **gc**: Shortcut for `git checkout`.
- **gb**: Shortcut for `git branch`.
- **gl**: Shortcut for `git log --oneline --graph --decorate -10`.
- **New-UEProject**: Creates a new Unreal Engine project with specified parameters.

## Troubleshooting

- **Logs**: Check the log file generated by the script for detailed information about the installation process. The log file is located at `%TEMP%\UnrealEngineSetup_<timestamp>.log`.
- **Restore**: If something goes wrong, you can restore your environment from the backup created by the script using the `Restore-Environment` function.
- **Manual Installation**: If the script fails to install a specific component, you can manually install it using Chocolatey or the official installer.

## Contributing

Contributions to the script are welcome! If you have suggestions for improvements or new features, please open an issue or submit a pull request on the repository.

## Acknowledgments

- **Chocolatey**: For providing a convenient package manager for Windows.
- **Epic Games**: For creating Unreal Engine and providing the necessary tools for game development.
- **Community**: For the various tools and libraries that make Unreal Engine development possible.

## Conclusion

This script aims to simplify the setup process for Unreal Engine developers, allowing you to focus on creating amazing games and experiences. If you encounter any issues or have feedback, please don't hesitate to reach out.
