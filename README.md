# Developer Environment Setup 🛠️

Automated provisioning for **High-Performance Engineering Environments**.
Supports **Fedora Linux** (Workstation) and **Windows 11** (PowerShell).

##  Overview

This repository automates the installation of my tech stack, dotfiles, and system configurations. It ensures consistency across my machines (Avell Storm & Desktop Ryzen).

### Features
- **Cross-Platform:** Smart detection for `dnf` (Fedora), `apt` (Debian/Ubuntu), and `Winget` (Windows).
- **Stack Provisioning:** Java 21, Python, Docker, Podman, and Build Tools.
- **IDE Management:** JetBrains Toolbox & VS Code (w/ extensions).
- **Visuals:** Auto-applies wallpaper and terminal theming.

##  Quick Start

### Linux (Fedora/Ubuntu)
```bash
git clone [https://github.com/pedroEKS/my-dev-setup.git](https://github.com/pedroEKS/my-dev-setup.git)
cd my-dev-setup
chmod +x install.sh
./install.sh