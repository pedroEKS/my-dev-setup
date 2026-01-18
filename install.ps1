# ==========================================
# Pedro Aureliano - Windows Setup Script
# Executar como Administrador
# ==========================================

Write-Host "[SETUP] Iniciando configuração do Windows..." -ForegroundColor Cyan

## Instalar Softwares (Winget)
Write-Host "[WINGET] Instalando softwares da lista..." -ForegroundColor Cyan
$packages = Get-Content -Path "packages\windows-winget.txt"
foreach ($id in $packages) {
    if ($id -and -not $id.StartsWith("#")) {
        Write-Host "Instalando: $id" -ForegroundColor Yellow
        winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements
    }
}

## Configurar VS Code
# Atualiza PATH para reconhecer o comando 'code'
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

if (Get-Command "code" -ErrorAction SilentlyContinue) {
    Write-Host "[VSCODE] Instalando extensões..." -ForegroundColor Cyan
    $extensions = Get-Content -Path "packages\vscode-ext.txt"
    foreach ($ext in $extensions) {
         if ($ext -and -not $ext.StartsWith("#")) {
             code --install-extension $ext --force
         }
    }
}

## Configurar PowerShell Profile
Write-Host "[POWERSHELL] Configurando perfil..." -ForegroundColor Cyan
$ProfileDir = Split-Path $PROFILE
if (!(Test-Path $ProfileDir)) { New-Item -Type Directory -Path $ProfileDir -Force }
Copy-Item -Path "configs\windows_profile.ps1" -Destination $PROFILE -Force

##Configurar Git
Copy-Item -Path "configs\.gitconfig" -Destination "$HOME\.gitconfig" -Force

## Aplicar Wallpaper 
Write-Host "[WALLPAPER] Aplicando visual..." -ForegroundColor Cyan
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
} else {
    Write-Host "[ERRO] MinDark.jpg não encontrado na pasta assets." -ForegroundColor Red
}

Write-Host "[SUCESSO] Windows configurado. Reinicie o Terminal." -ForegroundColor Green