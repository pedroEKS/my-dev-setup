# =====================================================
# Pedro Aureliano
# Automates the installation 
# Supports: Fedora (dnf) and Debian/Ubuntu (apt).
# =====================================================

#!/bin/bash

set -e  

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_task() { echo -e "${YELLOW}[TASK]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERRO]${NC} $1"; }

## REPOSITORIES AND PACKAGES SETUP

setup_fedora() {
    log_info "Fedora Linux detected. Configuring DNF..."
    
    #Optimize DNF (Parallel Downloads)
    if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
        echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
        echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
    fi

    # Add VS Code Repository
    log_task "Adding Microsoft repository (VS Code)..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

    # Add Hashicorp Repository (Terraform)
    log_task "Adding Hashicorp repository..."
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo

    # Add Docker Repository
    log_task "Adding Docker repository..."
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    # Install Packages
    log_task "Installing package list (packages/dnf.txt)..."
    sudo dnf update -y
    sudo dnf install -y $(grep -vE "^\s*#" packages/dnf.txt | tr "\n" " ")
}

setup_debian() {
    log_info "Debian/Ubuntu detected. Configuring APT..."
    
    sudo apt-get update
    sudo apt-get install -y wget gpg coreutils

    # Add VS Code Repository
    log_task "Setting up VS Code repository..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg

    # Add Hashicorp Repository (Terraform)
    log_task "Setting up Hashicorp repository..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

    # Add Docker Repository
    log_task "Setting up Docker repository..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Packages
    log_task "Installing package list (packages/apt.txt)..."
    sudo apt-get update
    sudo apt-get install -y $(grep -vE "^\s*#" packages/apt.txt | tr "\n" " ")
}

# CONFIGURATION SHELL\ TOOLS


setup_environment() {
    # Starship
    if ! command -v starship &> /dev/null; then
        log_task "Installing Starship Prompt..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    # Dotfiles
    log_task "Linking configurations (Git, Bash)..."
    cp configs/.gitconfig ~/.gitconfig
    
    # Safely inject into .bashrc
    if ! grep -q "STARSHIP_CONFIG" ~/.bashrc; then
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
    fi
    if ! grep -q "bash_custom" ~/.bashrc; then
        echo 'source $(pwd)/configs/.bash_custom' >> ~/.bashrc
    fi

    # VS Code Extensions
    if command -v code &> /dev/null; then
        log_task "Installing VS Code extensions..."
        while read -r ext; do
            [[ "$ext" =~ ^#.*$ ]] && continue
            [ -z "$ext" ] && continue
            code --install-extension "$ext" --force
        done < packages/vscode-ext.txt
    fi
}

# 3. KERNEL OPTIMIZATION TUNING


optimize_system() {
    log_task "Applying Kernel Tuning (Sysctl)..."
    
    # Increase file watchers (prevents ENOSPC error in VS Code/Webpack)
    echo "fs.inotify.max_user_watches=524288" | sudo tee /etc/sysctl.d/99-vscode-limits.conf > /dev/null
    
    # Increase memory map areas (Required for ElasticSearch/Sonarqube/Heavy Java apps)
    echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.d/99-vscode-limits.conf > /dev/null
    
    # Improve swap usage (only use swap when RAM is almost full)
    echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null

    # Apply without rebooting
    sudo sysctl --system > /dev/null
    log_success "Kernel optimized for Development!"
}

# MAIN EXECUTION

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    ID_LIKE=${ID_LIKE:-""}
fi

echo -e "${BLUE}=== PEDRO AURELIANO | LINUX SETUP ===${NC}"

if [[ "$OS" == "fedora" ]] || [[ "$ID_LIKE" == *"fedora"* ]]; then
    setup_fedora
elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
    setup_debian
else
    log_error "Unsupported distribution: $OS"
    exit 1
fi

setup_environment
optimize_system

log_success "Setup Finished. Please restart your terminal."