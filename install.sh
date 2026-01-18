# =====================================================
# Pedro Aureliano
# Automates the installation 
# Supports: Fedora (dnf) and Debian/Ubuntu (apt).
# =====================================================

#!/bin/bash
set -e 

# Cores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}[SETUP]${NC} Iniciando configuração do ambiente Linux..."

## Detectar OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    ID_LIKE=$ID_LIKE
fi

## Instalação de Pacotes
if [[ "$OS" == "fedora" ]] || [[ "$ID_LIKE" == *"fedora"* ]]; then
    echo -e "${BLUE}[DNF]${NC} Atualizando Fedora..."
    sudo dnf update -y
    sudo dnf install -y $(grep -vE "^\s*#" packages/dnf.txt | tr "\n" " ")
    sudo systemctl enable --now docker 2>/dev/null || true

elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
    echo -e "${BLUE}[APT]${NC} Atualizando Debian/Ubuntu..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y $(grep -vE "^\s*#" packages/apt.txt | tr "\n" " ")
fi

## JetBrains Toolbox (Instalação Automática)
echo -e "${BLUE}[JETBRAINS]${NC} Instalando Toolbox..."
TOOLBOX_URL=$(curl -s 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' | grep -Po '"linux":.*?"build":".*?",' | grep -Po '"link":".*?"' | grep -Po 'https://.*?.tar.gz')
wget -qO toolbox.tar.gz "$TOOLBOX_URL"
tar -xzf toolbox.tar.gz
DIR_NAME=$(find . -maxdepth 1 -type d -name "jetbrains-toolbox-*")
cd "$DIR_NAME"
./jetbrains-toolbox &
cd ..
rm -rf toolbox.tar.gz "$DIR_NAME"

## VS Code Extensions
if command -v code &> /dev/null; then
    echo -e "${BLUE}[VSCODE]${NC} Instalando extensões..."
    while read -r ext; do
        [[ "$ext" =~ ^#.*$ ]] && continue
        [ -z "$ext" ] && continue
        code --install-extension "$ext" --force
    done < packages/vscode-ext.txt
fi

## Configs & Dotfiles
echo -e "${BLUE}[CONFIG]${NC} Linkando dotfiles..."
# Bash Custom
if ! grep -q "bash_custom" ~/.bashrc; then
    echo "source $(pwd)/configs/.bash_custom" >> ~/.bashrc
fi
# Git Config
cp configs/.gitconfig ~/.gitconfig

## Wallpaper (Gnome)
WALLPAPER_PATH="$(pwd)/assets/MinDark.jpg"
if [ -f "$WALLPAPER_PATH" ] && [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
    echo -e "${BLUE}[WALLPAPER]${NC} Aplicando MinDark..."
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
fi

echo -e "${GREEN}[SUCESSO]${NC} Setup finalizado. Reinicie o terminal."