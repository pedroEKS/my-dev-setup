# =====================================================
# Pedro Aureliano
# Windows Setup Script
# Run this script in a PowerShell terminal with admin rights
# =====================================================

$ErrorActionPreference = "Stop"

Write-Host "[SETUP] Starting configuration..." -ForegroundColor Cyan
function Optimize-Windows {
    Write-Host "[TWEAK] Applying performance optimizations..." -ForegroundColor Magenta
    
    # Power Plan: High Performance
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
    powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61
    
    #TCP
    netsh int tcp set global autotuninglevel=normal | Out-Null

    # Remove Bloatware (CandyCrush, Xbox, etc)
    $bloat = @("*Solitaire*", "*BingWeather*", "*GetHelp*", "*SkypeApp*", "*Xbox*")
    foreach ($app in $bloat) {
        Get-AppxPackage -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
    }
    Write-Host " -> System optimized."
}

## Install Starship 
if (-not (Get-Command "starship" -ErrorAction SilentlyContinue)) {
    Write-Host "[STARSHIP] Installing Prompt..." -ForegroundColor Cyan
    winget install --id Starship.Starship -e --accept-package-agreements
}

## Install Apps 
Write-Host "[WINGET] Installing Software..." -ForegroundColor Cyan
$packages = Get-Content -Path "packages\windows-winget.txt"
foreach ($id in $packages) {
    if ($id -and -not $id.StartsWith("#")) {
        try {
            Write-Host "Installing: $id" -ForegroundColor Yellow
            winget install --id $id -e --accept-package-agreements --accept-source-agreements
        } catch {
            Write-Host "[SKIP] $id (Error or already installed)" -ForegroundColor DarkGray
        }
    }
}

## Configure VS Code Extensions
if (Get-Command "code" -ErrorAction SilentlyContinue) {
    Write-Host "[VSCODE] Installing extensions..." -ForegroundColor Cyan
    $extensions = Get-Content -Path "packages\vscode-ext.txt"
    foreach ($ext in $extensions) {
         if ($ext -and -not $ext.StartsWith("#")) {
             code --install-extension $ext --force
         }
    }
}

## Dotfiles\Profile
Write-Host "[CONFIG] Copying configs..." -ForegroundColor Cyan
Copy-Item -Path "configs\.gitconfig" -Destination "$HOME\.gitconfig" -Force

if (!(Test-Path $PROFILE)) { New-Item -Type File -Path $PROFILE -Force }

if (!(Select-String -Path $PROFILE -Pattern "starship init")) {
    Add-Content -Path $PROFILE -Value "`nInvoke-Expression (&starship init powershell)"
}
# Inject aliases
if (Test-Path "configs\windows_profile.ps1") {
    Get-Content "configs\windows_profile.ps1" | Add-Content -Path $PROFILE
}

Optimize-Windows

## Wallpaper
$wallpaperPath = "$PSScriptRoot\assets\MinDark.jpg"
if (Test-Path $wallpaperPath) {
    $code = @' 
    using System.Runtime.InteropServices; 
    public class Wallpaper { 
        [DllImport("user32.dll", CharSet=CharSet.Auto)] 
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni); 
    }
'@ 
    Add-Type -TypeDefinition $code 
    [Wallpaper]::SystemParametersInfo(20, 0, $wallpaperPath, 3)
}

Write-Host "[SUCCESS] Setup finished." -ForegroundColor Green