# =====================================================
# Pedro Aureliano
# Automates the installation 
# Supports: Fedora (dnf) and Debian/Ubuntu (apt).
# =====================================================
#!/bin/bash

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_task() { echo -e "${YELLOW}[TASK]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verifica arquivos necessários
required_files=("packages/dnf.txt" "packages/apt.txt" "packages/vscode-ext.txt" "configs/.gitconfig" "configs/.bash_custom")
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        log_error "Arquivo necessário não encontrado: $file"
        exit 1
    fi
done

setup_fedora() {
    log_info "Fedora detectado. Configurando DNF..."

    # Otimiza DNF se não configurado
    if ! grep -q "max_parallel_downloads=10" /etc/dnf/dnf.conf; then
        echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
        echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
    fi

    # Repos: VS Code, Hashicorp, Docker, Microsoft (.NET), Nodesource (Node.js)
    log_task "Adicionando repositórios..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[packages-microsoft-com-prod]\nname=packages-microsoft-com-prod \nbaseurl=https://packages.microsoft.com/rpm/repos/microsoft-prod\nenabled=1\ngpgcheck=1 \ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/microsoft-prod.repo'
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -

    sudo dnf update -y
    log_task "Instalando pacotes..."
    sudo dnf install -y $(grep -vE "^\s*#" packages/dnf.txt | tr "\n" " ")
}

setup_debian() {
    log_info "Debian/Ubuntu detectado. Configurando APT..."

    sudo apt-get update
    sudo apt-get install -y wget gpg coreutils lsb-release curl

    # Repos: VS Code, Hashicorp, Docker, Microsoft (.NET), Nodesource (Node.js)
    log_task "Adicionando repositórios..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg

    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'

    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

    sudo apt-get update
    log_task "Instalando pacotes..."
    sudo apt-get install -y $(grep -vE "^\s*#" packages/apt.txt | tr "\n" " ")
}

setup_environment() {
    # Starship (instala via pacote se possível, evita curl | sh)
    if ! command -v starship &> /dev/null; then
        log_task "Instalando Starship..."
        if [[ "$OS" == "fedora" ]]; then
            sudo dnf install -y starship
        else
            sudo apt-get install -y starship
        fi
    fi

    # Dotfiles com backup
    log_task "Linkando configs..."
    [ -f ~/.gitconfig ] && mv ~/.gitconfig ~/.gitconfig.bak
    cp configs/.gitconfig ~/.gitconfig

    # Injeta no .bashrc sem duplicatas
    if ! grep -q "starship init bash" ~/.bashrc; then
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
    fi
    if ! grep -q "source .*bash_custom" ~/.bashrc; then
        echo "source $(pwd)/configs/.bash_custom" >> ~/.bashrc
    fi

    # Extensões VS Code
    if command -v code &> /dev/null; then
        log_task "Instalando extensões VS Code..."
        while read -r ext; do
            [[ "$ext" =~ ^#.*$ || -z "$ext" ]] && continue
            code --install-extension "$ext" --force || log_error "Falha ao instalar $ext"
        done < packages/vscode-ext.txt
    fi
}

optimize_system() {
    log_task "Aplicando tuning de kernel..."
    sudo tee /etc/sysctl.d/99-dev-limits.conf > /dev/null <<EOF
fs.inotify.max_user_watches=524288
vm.max_map_count=262144
vm.swappiness=10
EOF
    sudo sysctl --system
    log_success "Kernel otimizado!"
}

# Execução principal
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
fi

echo -e "${BLUE}=== SETUP EKS ===${NC}"

if [[ "$OS" == "fedora" ]]; then
    setup_fedora
elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    setup_debian
else
    log_error "Distribuição não suportada: $OS"
    exit 1
fi

setup_environment
optimize_system

log_success "Setup concluído. Reinicie o terminal."