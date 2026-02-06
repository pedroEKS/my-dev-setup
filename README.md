# My dev setup =)

##  Overview

This repository contains **Infrastructure as Code (IaC)** scripts to bootstrap my development machines from zero to a production-ready state in minutes.

Unlike simple dotfiles or package installers, this project focuses on **OS-level Tuning** and **Environment Parity**. It configures the OS kernel (Linux) and Registry (Windows) to handle heavy compilation workloads (Java/Rust) and container orchestration, ensuring a consistent and high-performance setup across different machines.

##  Performance & Engineering Tuning

This setup applies specific optimizations to ensure maximum throughput for development tools and workflows.

###  Linux (Fedora Workstation / Debian)
* **Kernel Tuning (`sysctl`):**
    * `fs.inotify.max_user_watches`: Increased to prevent "ENOSPC" errors from file watchers like VS Code and Webpack.
    * `vm.max_map_count`: Raised to support memory-intensive applications like Elasticsearch and large JVM heaps.
    * `vm.swappiness`: Lowered to prioritize RAM usage and minimize disk I/O.
* **Package Manager:** Configures `dnf` for parallel downloads (10 streams), significantly reducing installation and update times.

###  Windows 11 (PowerShell)
* **Registry Optimizations:**
    * Programmatically enables the **Ultimate Performance** power plan.
    * Optimizes the TCP/IP stack (`autotuninglevel`) for lower network latency.
    * Disables telemetry and non-essential consumer bloatware (Ads, Candy Crush, etc.).
* **Tooling:** Automates the installation of Nerd Fonts and the Starship prompt for a modern terminal experience.

##  Getting Started

###  Linux Setup
Supports **Fedora** (primary), Ubuntu, and Debian.

```bash
# 1. Clone the repository
git clone https://github.com/eksdat/my-dev-setup.git
cd my-dev-setup

# 2. Grant execution permissions
chmod +x install.sh

# 3. Run the provisioner
./install.sh
```

### Windows Setup

Must be run from an **Administrator** PowerShell session.

```powershell
# 1. Set the execution policy to allow the script to run
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 2. Run the provisioner
.\install.ps1
```

## Project Structure

```text
my-dev-setup/
├── assets/                # Wallpapers and static resources
├── configs/               # Dotfiles (.gitconfig, .bash_custom)
├── packages/              # Package lists (Manifests)
│   ├── dnf.txt            # Fedora packages (dnf)
│   ├── apt.txt            # Debian/Ubuntu packages (apt)
│   ├── windows-winget.txt # Windows package IDs (winget)
│   └── vscode-ext.txt     # VS Code Extension IDs
├── install.ps1            # Windows Provisioning & Tuning Script
├── install.sh             # Linux Provisioning & Tuning Script
└── README.md              # This documentation
```

---
![CI](https://github.com/pedroEKS/my-dev-setup/actions/workflows/lint-ci.yml/badge.svg)

*Maintained by Pedro Aureliano.*
