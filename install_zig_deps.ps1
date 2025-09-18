# Script para instalar Zig e suas dependências no Windows 11
# Requer privilégios de administrador

param(
    [switch]$Force = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Instalador de Zig e Dependências" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Verificar se está executando como administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERRO: Este script precisa ser executado como administrador!" -ForegroundColor Red
    Write-Host "Clique com o botão direito no PowerShell e selecione 'Executar como administrador'" -ForegroundColor Yellow
    exit 1
}

# Função para verificar se um comando existe
function Test-Command {
    param($Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Instalar Chocolatey se não estiver instalado
if (-not (Test-Command "choco")) {
    Write-Host "Instalando Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Atualizar PATH para incluir Chocolatey
    $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")
    
    Write-Host "Chocolatey instalado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "Chocolatey já está instalado." -ForegroundColor Green
}

# Atualizar Chocolatey
Write-Host "Atualizando Chocolatey..." -ForegroundColor Yellow
choco upgrade chocolatey -y

# Instalar Zig
Write-Host "Instalando Zig..." -ForegroundColor Yellow
if ($Force) {
    choco install zig -y --force
} else {
    choco install zig -y
}

# Instalar dependências de desenvolvimento
Write-Host "Instalando dependências de desenvolvimento..." -ForegroundColor Yellow

# Git (necessário para package manager do Zig)
choco install git -y

# MSYS2 (para compilar bibliotecas C/C++)
choco install msys2 -y

# Visual Studio Build Tools (para linking)
choco install visualstudio2022buildtools -y --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools"

# LLVM (se necessário)
choco install llvm -y

# Atualizar variáveis de ambiente
Write-Host "Atualizando variáveis de ambiente..." -ForegroundColor Yellow
$env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")

# Verificar instalação
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Verificando instalações..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (Test-Command "zig") {
    $zigVersion = zig version
    Write-Host "✓ Zig instalado: $zigVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Zig não encontrado! Pode ser necessário reiniciar o terminal." -ForegroundColor Red
}

if (Test-Command "git") {
    $gitVersion = git --version
    Write-Host "✓ Git instalado: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Git não encontrado!" -ForegroundColor Red
}

# Verificar MSYS2 em múltiplas localizações
$msys2Paths = @(
    "C:\msys64",
    "C:\tools\msys64", 
    "${env:ProgramFiles}\msys64",
    "${env:ChocolateyInstall}\lib\msys2\tools\msys64"
)

$msys2Found = $false
foreach ($path in $msys2Paths) {
    if (Test-Path $path) {
        Write-Host "✓ MSYS2 instalado em $path" -ForegroundColor Green
        $msys2Found = $true
        break
    }
}

if (-not $msys2Found) {
    Write-Host "✗ MSYS2 não encontrado!" -ForegroundColor Red
    Write-Host "Locais verificados:" -ForegroundColor Yellow
    foreach ($path in $msys2Paths) {
        Write-Host "  - $path" -ForegroundColor Gray
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Instalação concluída!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IMPORTANTE: Reinicie o terminal para atualizar as variáveis de ambiente." -ForegroundColor Yellow
Write-Host "Próximo passo: Execute install_gtk4_deps.ps1 para instalar as dependências do GTK4." -ForegroundColor Yellow
