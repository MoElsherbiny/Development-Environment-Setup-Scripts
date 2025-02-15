#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colorful messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to update all packages
update_all_packages() {
    print_message "$BLUE" "Updating all development tools and packages..."

    # Update package managers
    if command_exists brew; then
        print_message "$YELLOW" "Updating Homebrew packages..."
        brew update && brew upgrade
    fi

    if command_exists apt; then
        print_message "$YELLOW" "Updating apt packages..."
        sudo apt update && sudo apt upgrade -y
    fi

    if command_exists dnf; then
        print_message "$YELLOW" "Updating dnf packages..."
        sudo dnf upgrade -y
    fi

    # Update Node.js packages
    if command_exists npm; then
        print_message "$YELLOW" "Updating npm and global packages..."
        npm update -g
    fi

    # Update Python packages
    if command_exists pip3; then
        print_message "$YELLOW" "Updating pip packages..."
        pip3 list --outdated --format=json | python3 -c "import json, sys; print('\n'.join([x['name'] for x in json.load(sys.stdin)]))" | xargs -n1 pip3 install -U
    fi

    # Update Ruby gems
    if command_exists gem; then
        print_message "$YELLOW" "Updating Ruby gems..."
        gem update
    fi

    # Update Rust
    if command_exists rustup; then
        print_message "$YELLOW" "Updating Rust..."
        rustup update
    fi

    print_message "$GREEN" "All packages have been updated!"
}

# Check if running as root on Linux
if [[ "$OSTYPE" == "linux-gnu"* && $EUID -ne 0 ]]; then
    print_message "$RED" "This script must be run as root on Linux. Please use sudo."
    exit 1
fi

print_message "$BLUE" "Starting development environment setup..."

# Create development directories
DIRS=("Projects" "Workspace" "Development" "GitHub" ".ssh" ".config")
for dir in "${DIRS[@]}"; do
    mkdir -p "$HOME/$dir"
    print_message "$GREEN" "Created directory: $HOME/$dir"
done

# Install package managers and basic tools
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS setup
    if ! command_exists brew; then
        print_message "$YELLOW" "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # Install macOS packages
    BREW_PACKAGES=(
        git
        node
        python
        go
        rust
        docker
        kubectl
        terraform
        aws-cli
        azure-cli
        jq
        wget
        curl
        tree
        tmux
        vim
        visual-studio-code
        iterm2
        firefox-developer-edition
        google-chrome
        postman
    )

    for package in "${BREW_PACKAGES[@]}"; do
        print_message "$YELLOW" "Installing $package..."
        brew install $package || brew install --cask $package
    done

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux setup
    if command_exists apt; then
        # Ubuntu/Debian
        print_message "$YELLOW" "Updating apt repositories..."
        sudo apt update

        # Install Linux packages
        APT_PACKAGES=(
            git
            curl
            wget
            build-essential
            python3
            python3-pip
            nodejs
            npm
            tmux
            vim
            jq
            tree
        )

        for package in "${APT_PACKAGES[@]}"; do
            print_message "$YELLOW" "Installing $package..."
            sudo apt install -y $package
        done

    elif command_exists dnf; then
        # Fedora/RHEL
        print_message "$YELLOW" "Updating dnf repositories..."
        sudo dnf update -y

        # Install Linux packages
        DNF_PACKAGES=(
            git
            curl
            wget
            gcc
            gcc-c++
            python3
            python3-pip
            nodejs
            npm
            tmux
            vim
            jq
            tree
        )

        for package in "${DNF_PACKAGES[@]}"; do
            print_message "$YELLOW" "Installing $package..."
            sudo dnf install -y $package
        done
    fi
fi

# Install Node.js global packages
if command_exists npm; then
    NODE_PACKAGES=(
        pnpm
        yarn
        typescript
        ts-node
        nodemon
        npm-check-updates
        @angular/cli
        create-react-app
        @vue/cli
        next
        nx
        eslint
        prettier
        serve
    )

    for package in "${NODE_PACKAGES[@]}"; do
        print_message "$YELLOW" "Installing Node.js package: $package..."
        npm install -g $package
    done
fi

# Install Python packages
if command_exists pip3; then
    PYTHON_PACKAGES=(
        virtualenv
        pipenv
        poetry
        black
        pylint
        pytest
        django
        flask
        fastapi
        uvicorn
        jupyter
        requests
        pandas
        numpy
    )

    for package in "${PYTHON_PACKAGES[@]}"; do
        print_message "$YELLOW" "Installing Python package: $package..."
        pip3 install --user $package
    done
fi

# Configure Git
print_message "$BLUE" "Configuring Git..."
git config --global core.autocrlf input
git config --global init.defaultBranch main
git config --global pull.rebase false

# Set up shell configuration
SHELL_RC="$HOME/.bashrc"
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
fi

# Add environment variables and aliases
cat << 'EOF' >> "$SHELL_RC"

# Development environment configuration
export PATH="$HOME/.local/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Aliases
alias g='git'
alias py='python3'
alias dps='docker ps'
alias dcp='docker-compose up'
alias dcpd='docker-compose up -d'
alias dcd='docker-compose down'
alias k='kubectl'
alias tf='terraform'

# Git aliases
alias gs='git status'
alias gp='git pull'
alias gps='git push'
alias gc='git checkout'
alias gb='git branch'

# Directory shortcuts
alias cdp='cd ~/Projects'
alias cdw='cd ~/Workspace'
alias cdg='cd ~/GitHub'

# Update development environment
update_dev_env() {
    echo "Updating development environment..."
    $(declare -f update_all_packages)
    update_all_packages
}

EOF

# Set up automatic updates (cron job)
CRON_CMD="0 9 * * 1 $HOME/.local/bin/update_dev_env.sh"
(crontab -l 2>/dev/null | grep -v "update_dev_env.sh"; echo "$CRON_CMD") | crontab -

# Create update script
mkdir -p "$HOME/.local/bin"
cat << 'EOF' > "$HOME/.local/bin/update_dev_env.sh"
#!/bin/bash
$(declare -f update_all_packages)
update_all_packages
EOF
chmod +x "$HOME/.local/bin/update_dev_env.sh"

print_message "$GREEN" "Setup complete! Development environment has been configured with:"
cat << EOF
1. Package Managers and Core Tools:
   - Homebrew (macOS) / apt/dnf (Linux)
   - Git, curl, wget
   - Build tools and utilities

2. Development Environments:
   - Node.js with npm, pnpm, yarn
   - Python with pip and various packages
   - Development directories

3. Configurations:
   - Git configuration
   - Shell aliases and functions
   - Environment variables
   - Automatic updates

4. Auto-Update Features:
   - Weekly updates (Monday at 9 AM)
   - Manual updates via 'update_dev_env' command

Next steps:
1. Restart your terminal or run: source $SHELL_RC
2. Run 'update_dev_env' to ensure all packages are up to date
3. Start using the new aliases and functions

Your development environment will automatically update every Monday at 9 AM.
You can manually update anytime by running 'update_dev_env' in your terminal.
EOF

print_message "$YELLOW" "Please restart your terminal for all changes to take effect."
