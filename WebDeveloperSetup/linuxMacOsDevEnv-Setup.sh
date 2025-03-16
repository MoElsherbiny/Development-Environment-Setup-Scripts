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

# Function to test tool version
test_tool_version() {
    local tool=$1
    local version
    if version=$($tool --version 2>/dev/null); then
        print_message "$GREEN" "$tool version: $version"
        return 0
    else
        print_message "$YELLOW" "$tool not found or version check failed"
        return 1
    fi
}

# Function to verify PATH entry
verify_path_entry() {
    local path_entry=$1
    if [[ ":$PATH:" != *":$path_entry:"* ]]; then
        print_message "$YELLOW" "WARNING: $path_entry is missing from PATH"
        return 1
    elif [ ! -d "$path_entry" ]; then
        print_message "$RED" "ERROR: $path_entry in PATH does not exist"
        return 1
    fi
    print_message "$GREEN" "Verified PATH entry: $path_entry"
    return 0
}

# Function to verify all PATH entries
verify_all_paths() {
    print_message "$BLUE" "Verifying PATH entries..."
    local missing_paths=()
    local required_paths=(
        "$HOME/.local/bin"
        "$HOME/go/bin"
        "$HOME/.cargo/bin"
        "$HOME/.npm-global/bin"
        "/usr/local/go/bin"
        "/usr/local/bin"
    )

    for path in "${required_paths[@]}"; do
        if ! verify_path_entry "$path"; then
            missing_paths+=("$path")
        fi
    done

    return ${#missing_paths[@]}
}

# Function to update all packages
update_all_packages() {
    print_message "$BLUE" "Updating all development tools and packages..."

    if command_exists brew; then
        brew update && brew upgrade
    fi

    if command_exists apt; then
        sudo apt update && sudo apt upgrade -y
    fi

    if command_exists dnf; then
        sudo dnf upgrade -y
    fi

    if command_exists npm; then
        npm update -g
    fi

    if command_exists pip3; then
        pip3 list --outdated --format=json | python3 -c "import json, sys; print('\n'.join([x['name'] for x in json.load(sys.stdin)]))" | xargs -n1 pip3 install -U
    fi

    if command_exists gem; then
        gem update
    fi

    if command_exists rustup; then
        rustup update
    fi

    print_message "$GREEN" "All packages updated successfully!"
}

# Check if running as root on Linux
if [[ "$OSTYPE" == "linux-gnu"* && $EUID -ne 0 ]]; then
    print_message "$RED" "This script must be run as root on Linux. Use sudo."
    exit 1
fi

print_message "$BLUE" "Starting development environment setup..."

# Create development directories
COMMON_DIRS=(
    "Projects"
    "Workspace"
    "Development"
    "GitHub"
    ".ssh"
    ".config"
    ".docker"
    "Downloads/Development"
)
for dir in "${COMMON_DIRS[@]}"; do
    mkdir -p "$HOME/$dir"
    print_message "$GREEN" "Created directory: $HOME/$dir"
done

# Install package managers and tools
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS setup
    if ! command_exists brew; then
        print_message "$YELLOW" "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # Backend Development Tools
    BREW_BACKEND=(
        python      # General-purpose language (Django, Flask)
        ruby        # Ruby language (Rails)
        go          # Go language (high-performance services)
        rust        # Rust language (system-level programming)
        openjdk@17  # Java runtime (Spring Boot)
        kotlin      # Kotlin language (Ktor)
        gradle      # Build tool for Java/Kotlin
        maven       # Another build tool for Java
    )

    # Frontend Development Tools
    BREW_FRONTEND=(
        node        # Node.js for JavaScript/TypeScript (React, Vue)
        visual-studio-code  # Lightweight editor
        jetbrains-toolbox   # For WebStorm, PyCharm, IntelliJ (optional IDEs)
    )

    # DevOps and Cloud Tools
    BREW_DEVOPS=(
        docker      # Container runtime
        kubernetes-cli  # kubectl for Kubernetes
        helm        # Package manager for Kubernetes
        minikube    # Local Kubernetes cluster
        terraform   # Infrastructure-as-code tool
        awscli      # AWS CLI
        azure-cli   # Azure CLI
        gh          # GitHub CLI
        ngrok       # Expose local servers
        ansible     # Configuration management
    )

    # Databases
    BREW_DATABASES=(
        mysql       # MySQL database server
        postgresql  # PostgreSQL database server
        mongodb-community  # MongoDB NoSQL database
        redis       # Redis in-memory data store
        dbeaver-community  # Universal database client GUI (cask)
    )

    # Productivity Utilities
    BREW_PRODUCTIVITY=(
        git         # Version control
        git-lfs     # Large file support for Git
        curl        # HTTP requests
        wget        # File downloads
        unzip       # ZIP extraction
        p7zip       # 7zip utility
        iterm2      # Modern terminal (alternative to Windows Terminal)
        starship    # Custom shell prompt (like Oh My Posh)
        jq          # JSON processor
        bat         # Enhanced 'cat'
        fzf         # Fuzzy finder
        postman     # API testing tool
        insomnia    # Alternative API client
        wireshark   # Network protocol analyzer
        gcc         # GCC compiler
        cmake       # Build system generator
        llvm        # LLVM compiler (includes Clang)
        ninja       # Lightweight build system
        shellcheck  # Shell script linting
        htop        # Process viewer
        gnupg       # Encryption tool
        openssh     # Secure shell
        ffmpeg      # Media processing
        pandoc      # Document conversion
    )

    # Browsers
    BREW_BROWSERS=(
        google-chrome       # Chrome browser
        firefox             # Firefox browser
        microsoft-edge      # Edge browser
    )

    # Install all tools
    for category in BACKEND FRONTEND DEVOPS DATABASES PRODUCTIVITY BROWSERS; do
        print_message "$BLUE" "Installing $category tools..."
        eval "packages=( \"\${BREW_$category[@]}\" )"
        for package in "${packages[@]}"; do
            print_message "$YELLOW" "Installing $package..."
            brew install $package || brew install --cask $package
        done
    done

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux setup
    if command_exists apt; then
        # Ubuntu/Debian
        print_message "$YELLOW" "Updating apt repositories..."
        sudo apt update

        # Backend Development Tools
        APT_BACKEND=(
            python3 python3-pip  # General-purpose language (Django, Flask)
            ruby                 # Ruby language (Rails)
            golang               # Go language
            rustc cargo          # Rust language
            openjdk-17-jdk       # Java runtime
            kotlin               # Kotlin language
            gradle               # Build tool
            maven                # Another build tool
        )

        # Frontend Development Tools
        APT_FRONTEND=(
            nodejs npm           # Node.js for JavaScript/TypeScript
            code                 # VS Code (requires snap or manual install)
        )

        # DevOps and Cloud Tools
        APT_DEVOPS=(
            docker.io            # Container runtime
            docker-compose       # Multi-container management
            kubernetes-tools     # kubectl (may need additional repo)
            helm                 # Kubernetes package manager (may need manual install)
            minikube             # Local Kubernetes (may need manual install)
            terraform            # Infrastructure-as-code (requires HashiCorp repo)
            awscli               # AWS CLI
            azure-cli            # Azure CLI (requires Microsoft repo)
            gh                   # GitHub CLI (requires GitHub repo)
            ngrok                # Expose local servers (requires manual install)
            ansible              # Configuration management
        )

        # Databases
        APT_DATABASES=(
            mysql-server         # MySQL database
            postgresql           # PostgreSQL database
            mongodb-org          # MongoDB (requires MongoDB repo)
            redis-server         # Redis in-memory store
        )

        # Productivity Utilities
        APT_PRODUCTIVITY=(
            git                  # Version control
            git-lfs              # Large file support
            curl                 # HTTP requests
            wget                 # File downloads
            unzip                # ZIP extraction
            p7zip-full           # 7zip utility
            jq                   # JSON processor
            bat                  # Enhanced 'cat' (may need batcat on Ubuntu)
            fzf                  # Fuzzy finder
            gcc                  # GCC compiler
            cmake                # Build system generator
            g++                  # C++ compiler
            make                 # Build automation
            shellcheck           # Shell script linting
            htop                 # Process viewer
            gnupg                # Encryption tool
            openssh-server       # Secure shell
            ffmpeg               # Media processing
            pandoc               # Document conversion
        )

        # Browsers
        APT_BROWSERS=(
            chromium-browser     # Chrome alternative
            firefox              # Firefox browser
        )

        # Install all tools
        for category in BACKEND FRONTEND DEVOPS DATABASES PRODUCTIVITY BROWSERS; do
            print_message "$BLUE" "Installing $category tools..."
            eval "packages=( \"\${APT_$category[@]}\" )"
            for package in "${packages[@]}"; do
                print_message "$YELLOW" "Installing $package..."
                sudo apt install -y $package
            done
        done

    elif command_exists dnf; then
        # Fedora/RHEL
        print_message "$YELLOW" "Updating dnf repositories..."
        sudo dnf update -y

        # Backend Development Tools
        DNF_BACKEND=(
            python3 python3-pip  # General-purpose language
            ruby                 # Ruby language
            golang               # Go language
            rust cargo           # Rust language
            java-17-openjdk-devel  # Java runtime
            kotlin               # Kotlin language
            gradle               # Build tool
            maven                # Another build tool
        )

        # Frontend Development Tools
        DNF_FRONTEND=(
            nodejs               # Node.js
        )

        # DevOps and Cloud Tools
        DNF_DEVOPS=(
            docker               # Container runtime
            docker-compose       # Multi-container management
            kubernetes-client    # kubectl
            helm                 # Kubernetes package manager (may need manual install)
            minikube             # Local Kubernetes (may need manual install)
            terraform            # Infrastructure-as-code (requires HashiCorp repo)
            awscli               # AWS CLI
            azure-cli            # Azure CLI (requires Microsoft repo)
            gh                   # GitHub CLI (requires GitHub repo)
            ansible              # Configuration management
        )

        # Databases
        DNF_DATABASES=(
            mysql-server         # MySQL database
            postgresql-server    # PostgreSQL database
            mongodb-server       # MongoDB (requires MongoDB repo)
            redis                # Redis in-memory store
        )

        # Productivity Utilities
        DNF_PRODUCTIVITY=(
            git                  # Version control
            git-lfs              # Large file support
            curl                 # HTTP requests
            wget                 # File downloads
            unzip                # ZIP extraction
            p7zip                # 7zip utility
            jq                   # JSON processor
            bat                  # Enhanced 'cat'
            fzf                  # Fuzzy finder
            gcc                  # GCC compiler
            cmake                # Build system generator
            gcc-c++              # C++ compiler
            make                 # Build automation
            shellcheck           # Shell script linting
            htop                 # Process viewer
            gnupg                # Encryption tool
            openssh-server       # Secure shell
            ffmpeg               # Media processing
            pandoc               # Document conversion
        )

        # Browsers
        DNF_BROWSERS=(
            chromium             # Chrome alternative
            firefox              # Firefox browser
        )

        # Install all tools
        for category in BACKEND FRONTEND DEVOPS DATABASES PRODUCTIVITY BROWSERS; do
            print_message "$BLUE" "Installing $category tools..."
            eval "packages=( \"\${DNF_$category[@]}\" )"
            for package in "${packages[@]}"; do
                print_message "$YELLOW" "Installing $package..."
                sudo dnf install -y $package
            done
        done
    fi
fi

# Install Node.js global packages (common across platforms)
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
        vercel
        netlify-cli
        firebase-tools
        webpack-cli
        vite
        jest
        cypress
    )
    for package in "${NODE_PACKAGES[@]}"; do
        print_message "$YELLOW" "Installing Node.js package: $package..."
        npm install -g $package
    done
fi

# Install Python packages (common across platforms)
if command_exists pip3; then
    PYTHON_PACKAGES=(
        virtualenv
        pipenv
        poetry
        black
        pylint
        mypy
        flake8
        pytest
        django
        flask
        fastapi
        uvicorn
        jupyter
        pandas
        numpy
        matplotlib
        requests
    )
    for package in "${PYTHON_PACKAGES[@]}"; do
        print_message "$YELLOW" "Installing Python package: $package..."
        pip3 install --user $package
    done
fi

# Configure Git
print_message "$BLUE" "Configuring Git..."
git config --global user.name "Your Name" # Replace with your name
git config --global user.email "your.email@example.com" # Replace with your email
git config --global core.autocrlf input
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.fileMode true
git config --global core.symlinks true
git config --global credential.helper store

# Set up shell configuration
SHELL_RC="$HOME/.bashrc"
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
fi

cat << 'EOF' >> "$SHELL_RC"
# Development environment configuration
export PATH="$HOME/.local/bin:$HOME/go/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin:/usr/local/go/bin:/usr/local/bin:$PATH"
export GOPATH="$HOME/go"
export NODE_PATH="$HOME/.npm-global"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# Aliases
alias g='git'
alias py='python3'
alias dps='docker ps'
alias dcp='docker-compose up'
alias k='kubectl'
alias tf='terraform'
alias gs='git status'
alias gp='git pull'
alias gps='git push'
alias cdp='cd ~/Projects'
alias cdw='cd ~/Workspace'
alias cdg='cd ~/GitHub'

# Update function
update_dev_env() {
    echo "Updating development environment..."
    $(declare -f update_all_packages)
    update_all_packages
}
EOF

# Set up cron job for weekly updates
CRON_CMD="0 9 * * 1 $HOME/.local/bin/update_dev_env.sh"
(crontab -l 2>/dev/null | grep -v "update_dev_env.sh"; echo "$CRON_CMD") | crontab -
mkdir -p "$HOME/.local/bin"
cat << 'EOF' > "$HOME/.local/bin/update_dev_env.sh"
#!/bin/bash
$(declare -f update_all_packages)
update_all_packages
EOF
chmod +x "$HOME/.local/bin/update_dev_env.sh"

# Validation
validate_installation() {
    print_message "$BLUE" "Validating installation..."
    local tools=("git" "node" "python3" "docker" "kubectl" "terraform" "aws" "code")
    for tool in "${tools[@]}"; do
        test_tool_version "$tool"
    done
    verify_all_paths
    print_message "$GREEN" "Setup validated successfully!"
}

# Final output
print_message "$GREEN" "Setup complete! Your development environment includes:"
cat << EOF
1. Backend Tools: Python, Ruby, Go, Rust, Java, Kotlin, Gradle, Maven
2. Frontend Tools: Node.js, VS Code
3. DevOps Tools: Docker, Kubernetes, Terraform, AWS CLI, Azure CLI, GitHub CLI
4. Databases: MySQL, PostgreSQL, MongoDB, Redis
5. Productivity: Git, curl, wget, bat, fzf, jq, htop, shellcheck
6. Automation: Weekly updates (Monday 9 AM), 'update_dev_env' command

Next Steps:
1. Restart your terminal: source $SHELL_RC
2. Run 'update_dev_env' to update all packages
3. Customize Git: Update user.name and user.email in ~/.gitconfig
EOF

validate_installation
print_message "$YELLOW" "Restart your terminal to apply changes."
