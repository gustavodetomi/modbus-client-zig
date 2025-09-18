param(
    [switch]$Watch = $false,
    [switch]$Clean = $false,
    [switch]$NoRun = $false,
    [switch]$Verbose = $false
)

Write-Host "Instalando dependências Zig..."
./install_zig_deps.ps1

Write-Host "Instalando dependências GTK4..."
./install_gtk4_deps.ps1

# Compila em modo debug

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Compilando em modo debug..."

Write-Host "🚀 DEV MODE - Zig GTK4 Application" -ForegroundColor Magenta
zig build

Write-Host "========================================" -ForegroundColor Magenta

# Executa o binário gerado

# Função para verificar se um comando existe
$exePath = "./build/bin/gtk4-app.exe"

function Test-Command {
    param($Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

if (Test-Path $exePath) {
    Write-Host "Executando $exePath..."
    & $exePath
} else {
    Write-Host "Arquivo $exePath não encontrado. Verifique se a compilação foi bem-sucedida."
}

# Função para verificar dependências rapidamente
function Test-Dependencies {
    Write-Host "Verificando dependências..." -ForegroundColor Yellow
    
    # Verificar Zig
    if (-not (Test-Command "zig")) {
        Write-Host "⚠️  Zig não encontrado - instalando..." -ForegroundColor Yellow
        & "$PSScriptRoot\install_zig_deps.ps1"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Falha ao instalar Zig!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "✅ Zig encontrado" -ForegroundColor Green
    }
    
    # Verificar GTK4
    $msys2Paths = @(
        "C:\msys64",
        "C:\tools\msys64",
        "${env:ProgramFiles}\msys64",
        "${env:ChocolateyInstall}\lib\msys2\tools\msys64"
    )
    
    $msys2Found = $false
    foreach ($path in $msys2Paths) {
        if (Test-Path "$path\mingw64\lib") {
            $msys2Found = $true
            Write-Host "✅ GTK4 encontrado em: $path" -ForegroundColor Green
            break
        }
    }
    
    if (-not $msys2Found) {
        Write-Host "⚠️  GTK4 não encontrado - instalando..." -ForegroundColor Yellow
        & "$PSScriptRoot\install_gtk4_deps.ps1"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Falha ao instalar GTK4!" -ForegroundColor Red
            exit 1
        }
    }
}

# Função para compilar e executar
function Build-And-Run {
    Write-Host "🔨 Compilando em modo debug..." -ForegroundColor Cyan
    
    $buildArgs = @("-BuildType", "Debug")
    if ($Clean) { $buildArgs += "-Clean" }
    if (-not $NoRun) { $buildArgs += "-Run" }
    if ($Verbose) { $buildArgs += "-Verbose" }
    
    & "$PSScriptRoot\build.ps1" @buildArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Build concluído com sucesso!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Erro na compilação!" -ForegroundColor Red
        return $false
    }
}

# Função para modo watch
function Start-WatchMode {
    Write-Host "👀 Modo watch ativado - monitorando mudanças em src/..." -ForegroundColor Cyan
    Write-Host "Pressione Ctrl+C para parar" -ForegroundColor Yellow
    
    $srcPath = Join-Path $PSScriptRoot "src"
    
    # Primeira compilação
    if (-not (Build-And-Run)) {
        return
    }
    
    # Monitorar mudanças
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $srcPath
    $watcher.Filter = "*.zig"
    $watcher.EnableRaisingEvents = $true
    $watcher.IncludeSubdirectories = $true
    
    $lastBuild = Get-Date
    
    Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action {
        $now = Get-Date
        $timeSinceLastBuild = ($now - $script:lastBuild).TotalSeconds
        
        # Evitar builds múltiplos em sequência rápida
        if ($timeSinceLastBuild -gt 2) {
            Write-Host "`n🔄 Mudança detectada - recompilando..." -ForegroundColor Cyan
            $script:lastBuild = $now
            
            # Executar build em background para não bloquear o watcher
            Start-Job -ScriptBlock {
                param($scriptRoot)
                & "$scriptRoot\build.ps1" -BuildType Debug -Run
            } -ArgumentList $PSScriptRoot | Out-Null
        }
    }
    
    try {
        # Manter o script ativo
        while ($true) {
            Start-Sleep 1
        }
    } finally {
        $watcher.Dispose()
        Write-Host "`n👋 Modo watch finalizado" -ForegroundColor Yellow
    }
}

# Verificar se estamos no diretório correto
if (-not (Test-Path "src\main.zig")) {
    Write-Host "❌ Execute este script na raiz do projeto (onde está src\main.zig)" -ForegroundColor Red
    exit 1
}

# Verificar dependências
Test-Dependencies

# Executar baseado nos parâmetros
if ($Watch) {
    Start-WatchMode
} else {
    $success = Build-And-Run
    
    if ($success -and -not $NoRun) {
        Write-Host "`n🎉 Aplicação executada com sucesso!" -ForegroundColor Green
        Write-Host "💡 Dica: Use -Watch para recompilação automática" -ForegroundColor Cyan
        Write-Host "💡 Exemplo: .\dev.ps1 -Watch" -ForegroundColor Cyan
    }
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "✨ DEV MODE - Concluído!" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Comandos úteis:" -ForegroundColor Cyan
Write-Host "  .\dev.ps1           - Build debug + executar" -ForegroundColor Gray
Write-Host "  .\dev.ps1 -Watch    - Modo watch (auto-rebuild)" -ForegroundColor Gray
Write-Host "  .\dev.ps1 -Clean    - Limpar build anterior" -ForegroundColor Gray
Write-Host "  .\dev.ps1 -NoRun    - Apenas compilar" -ForegroundColor Gray
Write-Host "  .\dev.ps1 -Verbose  - Output detalhado" -ForegroundColor Gray