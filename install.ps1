# =====================================================
# Pedro Aureliano
# Windows Setup Script
# Run this script in a PowerShell terminal with admin rights
# =====================================================
$ErrorActionPreference = "Stop"

# Verifica admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Rode como Administrator."
    exit 1
}

$scriptDir = Split-Path $PSCommandPath -Parent

Write-Host "[SETUP] Iniciando..." -ForegroundColor Cyan

function Optimize-Windows {
    Write-Host "[TWEAK] Otimizando performance..." -ForegroundColor Magenta
    
    # Plano de energia Ultimate Performance
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
    powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61
    
    # TCP
    netsh int tcp set global autotuninglevel=normal | Out-Null

    # Remove bloatware com match melhor
    $bloatPatterns = @("Microsoft.Solitaire", "Microsoft.BingWeather", "Microsoft.GetHelp", "Microsoft.SkypeApp", "Microsoft.Xbox")
    Get-AppxPackage | Where-Object { $bloatPatterns -contains $_.Name.Split('.')[1] } | Remove-AppxPackage -ErrorAction SilentlyContinue
    
    Write-Host " -> Sistema otimizado."
}

# Instala Starship
if (-not (Get-Command "starship" -ErrorAction SilentlyContinue)) {
    Write-Host "[STARSHIP] Instalando..." -ForegroundColor Cyan
    winget install --id Starship.Starship -e --accept-package-agreements --accept-source-agreements
}

# Instala apps
$packagesPath = Join-Path $scriptDir "packages\windows-winget.txt"
if (Test-Path $packagesPath) {
    Write-Host "[WINGET] Instalando apps..." -ForegroundColor Cyan
    $packages = Get-Content -Path $packagesPath | Where-Object { $_ -and -not $_.StartsWith("#") }
    foreach ($id in $packages) {
        try {
            Write-Host "Instalando: $id" -ForegroundColor Yellow
            winget install --id $id -e --accept-package-agreements --accept-source-agreements
        } catch {
            Write-Host "[SKIP] $id (erro ou já instalado)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Error "Lista de pacotes não encontrada: $packagesPath"
}

# Extensões VS Code
if (Get-Command "code" -ErrorAction SilentlyContinue) {
    Write-Host "[VSCODE] Instalando extensões..." -ForegroundColor Cyan
    $extPath = Join-Path $scriptDir "packages\vscode-ext.txt"
    if (Test-Path $extPath) {
        $extensions = Get-Content -Path $extPath | Where-Object { $_ -and -not $_.StartsWith("#") }
        foreach ($ext in $extensions) {
            code --install-extension $ext --force
        }
    }
}

# Configs
Write-Host "[CONFIG] Copiando configs..." -ForegroundColor Cyan
$gitConfigPath = Join-Path $scriptDir "configs\.gitconfig"
if (Test-Path $gitConfigPath) {
    Copy-Item -Path $gitConfigPath -Destination "$HOME\.gitconfig" -Force
}

$profilePath = $PROFILE
if (!(Test-Path $profilePath)) { New-Item -Type File -Path $profilePath -Force }

# Injeta Starship se instalado
if (Get-Command "starship" -ErrorAction SilentlyContinue) {
    if (!(Select-String -Path $profilePath -Pattern "starship init")) {
        Add-Content -Path $profilePath -Value "`nInvoke-Expression (&starship init powershell)"
    }
}

# Injeta aliases
$winProfilePath = Join-Path $scriptDir "configs\windows_profile.ps1"
if (Test-Path $winProfilePath) {
    Get-Content $winProfilePath | Add-Content -Path $profilePath
}

Optimize-Windows

# Wallpaper
$wallpaperPath = Join-Path $scriptDir "assets\MinDark.jpg"
if (Test-Path $wallpaperPath) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallPaper" -Value $wallpaperPath
    RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
}

Write-Host "[SUCCESS] Setup concluído." -ForegroundColor Green