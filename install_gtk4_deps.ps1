# Script para instalar dependências do GTK4 no Windows 11
# Requer privilégios de administrador

param(
    [switch]$Force = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Instalador de Dependências GTK4" -ForegroundColor Cyan
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

# Verificar se Chocolatey está instalado
if (-not (Test-Command "choco")) {
    Write-Host "ERRO: Chocolatey não está instalado!" -ForegroundColor Red
    Write-Host "Execute primeiro o script install_zig_deps.ps1" -ForegroundColor Yellow
    exit 1
}

# Verificar se MSYS2 está instalado e encontrar sua localização
$msys2Paths = @(
    "C:\msys64",
    "C:\tools\msys64",
    "${env:ProgramFiles}\msys64",
    "${env:ChocolateyInstall}\lib\msys2\tools\msys64"
)

$msys2Path = $null
foreach ($path in $msys2Paths) {
    if (Test-Path $path) {
        $msys2Path = $path
        Write-Host "MSYS2 encontrado em: $path" -ForegroundColor Green
        break
    }
}

if ($msys2Path -eq $null) {
    Write-Host "ERRO: MSYS2 não está instalado ou não foi encontrado!" -ForegroundColor Red
    Write-Host "Locais verificados:" -ForegroundColor Yellow
    foreach ($path in $msys2Paths) {
        Write-Host "  - $path" -ForegroundColor Gray
    }
    Write-Host "Execute primeiro o script install_zig_deps.ps1" -ForegroundColor Yellow
    exit 1
}

# Instalar PKG-CONFIG via Chocolatey
Write-Host "Instalando pkg-config..." -ForegroundColor Yellow
choco install pkgconfiglite -y

# Instalar GTK4 e dependências via MSYS2
Write-Host "Instalando GTK4 e dependências via MSYS2..." -ForegroundColor Yellow

# Atualizar MSYS2
Write-Host "Atualizando MSYS2..." -ForegroundColor Yellow
$bashPath = Join-Path $msys2Path "usr\bin\bash.exe"
if (-not (Test-Path $bashPath)) {
    Write-Host "ERRO: bash.exe não encontrado em $bashPath" -ForegroundColor Red
    exit 1
}

& $bashPath -lc "pacman -Syu --noconfirm"

# Instalar ferramentas de desenvolvimento
Write-Host "Instalando ferramentas de desenvolvimento..." -ForegroundColor Yellow
& $bashPath -lc "pacman -S --noconfirm base-devel mingw-w64-x86_64-toolchain"

# Instalar GTK4 e bibliotecas relacionadas
Write-Host "Instalando GTK4..." -ForegroundColor Yellow
& $bashPath -lc "pacman -S --noconfirm mingw-w64-x86_64-gtk4"

# Instalar bibliotecas de suporte
Write-Host "Instalando bibliotecas de suporte..." -ForegroundColor Yellow
& $bashPath -lc "pacman -S --noconfirm mingw-w64-x86_64-glib2 mingw-w64-x86_64-gobject-introspection mingw-w64-x86_64-cairo mingw-w64-x86_64-pango mingw-w64-x86_64-gdk-pixbuf2"

# Instalar pkg-config no MSYS2
Write-Host "Instalando pkg-config no MSYS2..." -ForegroundColor Yellow
& $bashPath -lc "pacman -S --noconfirm mingw-w64-x86_64-pkg-config"

# Configurar variáveis de ambiente
Write-Host "Configurando variáveis de ambiente..." -ForegroundColor Yellow

# Adicionar caminhos do MSYS2 ao PATH do sistema
$msys2Paths = @(
    "$msys2Path\mingw64\bin",
    "$msys2Path\usr\bin"
)

$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
foreach ($path in $msys2Paths) {
    if ($currentPath -notlike "*$path*") {
        Write-Host "Adicionando $path ao PATH do sistema..." -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$path", "Machine")
        $currentPath = "$currentPath;$path"
    }
}

# Configurar PKG_CONFIG_PATH
$pkgConfigPath = "$msys2Path\mingw64\lib\pkgconfig"
[Environment]::SetEnvironmentVariable("PKG_CONFIG_PATH", $pkgConfigPath, "Machine")
Write-Host "PKG_CONFIG_PATH configurado para: $pkgConfigPath" -ForegroundColor Yellow

# Configurar GTK_PATH
$gtkPath = "$msys2Path\mingw64"
[Environment]::SetEnvironmentVariable("GTK_PATH", $gtkPath, "Machine")
Write-Host "GTK_PATH configurado para: $gtkPath" -ForegroundColor Yellow

# Atualizar PATH da sessão atual
$env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")
$env:PKG_CONFIG_PATH = $pkgConfigPath
$env:GTK_PATH = $gtkPath

# Criar arquivo de configuração para Zig
Write-Host "Criando arquivo de configuração para Zig..." -ForegroundColor Yellow
$zigConfigContent = @"
# Configuração GTK4 para Zig
# Use estas configurações no seu build.zig

# Caminhos das bibliotecas (ajustado para localização do MSYS2)
GTK4_LIB_PATH = "$($gtkPath.Replace('\', '/'))/lib"
GTK4_INCLUDE_PATH = "$($gtkPath.Replace('\', '/'))/include"
GTK4_BIN_PATH = "$($gtkPath.Replace('\', '/'))/bin"

# Bibliotecas necessárias para linking
GTK4_LIBS = [
    "gtk-4",
    "gobject-2.0",
    "glib-2.0",
    "cairo",
    "pango-1.0",
    "pangocairo-1.0",
    "gdk_pixbuf-2.0",
]

# Flags de compilação (ajustado para localização do MSYS2)
GTK4_CFLAGS = [
    "-I$($gtkPath.Replace('\', '/'))/include/gtk-4.0",
    "-I$($gtkPath.Replace('\', '/'))/include/glib-2.0",
    "-I$($gtkPath.Replace('\', '/'))/lib/glib-2.0/include",
    "-I$($gtkPath.Replace('\', '/'))/include/cairo",
    "-I$($gtkPath.Replace('\', '/'))/include/pango-1.0",
    "-I$($gtkPath.Replace('\', '/'))/include/gdk-pixbuf-2.0",
]

# Caminho MSYS2 detectado: $msys2Path
"@

$zigConfigContent | Out-File -FilePath "gtk4_config.txt" -Encoding UTF8

# Verificar instalações
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Verificando instalações..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Verificar pkg-config
if (Test-Command "pkg-config") {
    Write-Host "✓ pkg-config instalado" -ForegroundColor Green
    
    # Testar se GTK4 é detectado pelo pkg-config
    try {
        $gtkVersion = & pkg-config --modversion gtk4 2>$null
        if ($gtkVersion) {
            Write-Host "✓ GTK4 detectado: versão $gtkVersion" -ForegroundColor Green
        } else {
            Write-Host "⚠ GTK4 instalado mas não detectado pelo pkg-config" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠ Erro ao verificar versão do GTK4" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ pkg-config não encontrado!" -ForegroundColor Red
}

# Verificar bibliotecas GTK4
$gtkLibPath = "$msys2Path\mingw64\lib"
$gtkLibs = @("libgtk-4.dll.a", "libgobject-2.0.dll.a", "libglib-2.0.dll.a")

foreach ($lib in $gtkLibs) {
    $libPath = Join-Path $gtkLibPath $lib
    if (Test-Path $libPath) {
        Write-Host "✓ $lib encontrado" -ForegroundColor Green
    } else {
        Write-Host "✗ $lib não encontrado!" -ForegroundColor Red
    }
}

# Verificar headers GTK4
$gtkIncludePath = "$msys2Path\mingw64\include\gtk-4.0"
if (Test-Path $gtkIncludePath) {
    Write-Host "✓ Headers GTK4 encontrados em $gtkIncludePath" -ForegroundColor Green
} else {
    Write-Host "✗ Headers GTK4 não encontrados!" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Instalação GTK4 concluída!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IMPORTANTE: Reinicie o terminal para atualizar as variáveis de ambiente." -ForegroundColor Yellow
Write-Host "Arquivo de configuração criado: gtk4_config.txt" -ForegroundColor Yellow
Write-Host "Próximo passo: Execute build.ps1 para compilar a aplicação." -ForegroundColor Yellow
