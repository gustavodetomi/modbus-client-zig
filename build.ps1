# Script de build para aplicação Zig com GTK4
# Compila um executável standalone com todas as dependências

param(
    [string]$BuildType = "Debug",
    [switch]$Clean = $false,
    [switch]$Run = $false,
    [switch]$Verbose = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build Script - Zig GTK4 Application" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Função para verificar se um comando existe
function Test-Command {
    param($Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Verificar se Zig está instalado
if (-not (Test-Command "zig")) {
    Write-Host "ERRO: Zig não está instalado!" -ForegroundColor Red
    Write-Host "Execute primeiro o script install_zig_deps.ps1" -ForegroundColor Yellow
    exit 1
}

# Verificar se as dependências GTK4 estão instaladas e encontrar MSYS2
$msys2Paths = @(
    "C:\msys64",
    "C:\tools\msys64",
    "${env:ProgramFiles}\msys64",
    "${env:ChocolateyInstall}\lib\msys2\tools\msys64"
)

$msys2Path = $null
foreach ($path in $msys2Paths) {
    if (Test-Path "$path\mingw64\lib") {
        $msys2Path = $path
        Write-Host "MSYS2 encontrado em: $path" -ForegroundColor Green
        break
    }
}

if ($msys2Path -eq $null) {
    Write-Host "ERRO: Dependências GTK4 não encontradas!" -ForegroundColor Red
    Write-Host "Execute primeiro o script install_gtk4_deps.ps1" -ForegroundColor Yellow
    exit 1
}

$gtkLibPath = "$msys2Path\mingw64\lib"
$gtkBinPath = "$msys2Path\mingw64\bin"

# Configurar variáveis de ambiente para o build
$env:PKG_CONFIG_PATH = "$msys2Path\mingw64\lib\pkgconfig"
$env:GTK_PATH = "$msys2Path\mingw64"
$env:PATH = "$msys2Path\mingw64\bin;$msys2Path\usr\bin;" + $env:PATH

# Definir caminhos
$projectRoot = $PSScriptRoot
$srcDir = Join-Path $projectRoot "src"
$buildDir = Join-Path $projectRoot "build"
$binDir = Join-Path $buildDir "bin"
$mainFile = Join-Path $srcDir "main.zig"

# Verificar se o arquivo principal existe
if (-not (Test-Path $mainFile)) {
    Write-Host "ERRO: Arquivo principal não encontrado: $mainFile" -ForegroundColor Red
    exit 1
}

# Limpar build anterior se solicitado
if ($Clean -and (Test-Path $buildDir)) {
    Write-Host "Limpando build anterior..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $buildDir
}

# Criar diretórios de build
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir | Out-Null
}

# Configurar parâmetros de build
$outputName = "gtk4-app.exe"
$outputPath = Join-Path $binDir $outputName

# Definir flags de compilação baseado no tipo de build
$buildFlags = @()
$linkFlags = @()

switch ($BuildType.ToLower()) {
    "debug" {
        $buildFlags += @("-O", "Debug")
        Write-Host "Configuração: Debug" -ForegroundColor Yellow
    }
    "release" {
        $buildFlags += @("-O", "ReleaseFast", "--subsystem", "windows")
        Write-Host "Configuração: Release (GUI - sem terminal)" -ForegroundColor Yellow
    }
    "releaseoptimized" {
        $buildFlags += @("-O", "ReleaseFast", "-fstrip", "--subsystem", "windows")
        Write-Host "Configuração: Release Otimizado (GUI - sem terminal)" -ForegroundColor Yellow
    }
    "production" {
        $buildFlags += @("-O", "ReleaseFast", "-fstrip", "--subsystem", "windows")
        Write-Host "Configuração: Produção (GUI - sem terminal, otimizado)" -ForegroundColor Yellow
    }
    default {
        $buildFlags += @("-O", "Debug")
        Write-Host "Configuração: Debug (padrão)" -ForegroundColor Yellow
    }
}

# Adicionar flags verbosas se solicitado
if ($Verbose) {
    $buildFlags += "--verbose"
}

# Configurar paths das bibliotecas GTK4 usando caminhos completos
$libPath = "$($msys2Path.Replace('\', '/'))/mingw64/lib"
$gtkLibFiles = @(
    "$libPath/libgtk-4.dll.a",
    "$libPath/libpangowin32-1.0.dll.a",
    "$libPath/libpangocairo-1.0.dll.a",
    "$libPath/libpango-1.0.dll.a",
    "$libPath/libgdk_pixbuf-2.0.dll.a",
    "$libPath/libcairo-gobject.dll.a",
    "$libPath/libcairo.dll.a",
    "$libPath/libgio-2.0.dll.a",
    "$libPath/libgobject-2.0.dll.a",
    "$libPath/libglib-2.0.dll.a"
)

$gtkIncludes = @(
    "$($msys2Path.Replace('\', '/'))/mingw64/include/gtk-4.0",
    "$($msys2Path.Replace('\', '/'))/mingw64/include/pango-1.0", 
    "$($msys2Path.Replace('\', '/'))/mingw64/include/harfbuzz",
    "$($msys2Path.Replace('\', '/'))/mingw64/include/fribidi",
    "$($msys2Path.Replace('\', '/'))/mingw64/include",
    "$($msys2Path.Replace('\', '/'))/mingw64/include/gdk-pixbuf-2.0",
    "$($msys2Path.Replace('\', '/'))/mingw64/include/webp",
    "$($msys2Path.Replace('\', '/'))/mingw64/include/cairo",
    "$($msys2Path.Replace('\', '/'))/mingw64/include/freetype2",
    "$($msys2Path.Replace('\', '/'))/mingw64/include/libpng16",
    "$($msys2Path.Replace('\', '/'))/mingw64/include/pixman-1",
    "$($msys2Path.Replace('\', '/'))/mingw64/include/graphene-1.0",
    "$($msys2Path.Replace('\', '/'))/mingw64/lib/graphene-1.0/include",
    "$($msys2Path.Replace('\', '/'))/mingw64/include/glib-2.0",
    "$($msys2Path.Replace('\', '/'))/mingw64/lib/glib-2.0/include",
    "$($msys2Path.Replace('\', '/'))/mingw64/include/gio-win32-2.0"
)

# Construir comando de compilação
$zigArgs = @("build-exe", $mainFile)
$zigArgs += $buildFlags
$zigArgs += @("--name", "gtk4-app")
$zigArgs += @("-femit-bin=$outputPath")

# Adicionar library path
$zigArgs += @("-L", "$($msys2Path.Replace('\', '/'))/mingw64/lib")

# Adicionar bibliotecas usando caminhos completos
foreach ($libFile in $gtkLibFiles) {
    if (Test-Path $libFile.Replace('/', '\')) {
        $zigArgs += $libFile
    } else {
        Write-Host "Aviso: Biblioteca não encontrada: $libFile" -ForegroundColor Yellow
    }
}

# Adicionar includes
foreach ($include in $gtkIncludes) {
    $zigArgs += @("-I", $include)
}

# Adicionar flags específicos do Windows
$zigArgs += @("-lc", "-lm", "-luser32", "-lgdi32", "-lshell32", "-lole32", "-luuid", "-lcomctl32", "-lcomdlg32")

# Executar build
Write-Host "Compilando aplicação..." -ForegroundColor Yellow
Write-Host "Comando: zig $($zigArgs -join ' ')" -ForegroundColor Gray

try {
    $process = Start-Process -FilePath "zig" -ArgumentList $zigArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Host "✓ Compilação bem-sucedida!" -ForegroundColor Green
        Write-Host "Executável criado: $outputPath" -ForegroundColor Green
        
        # Verificar se o arquivo foi criado
        if (Test-Path $outputPath) {
            $fileInfo = Get-Item $outputPath
            Write-Host "Tamanho do executável: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Cyan
        }
        
        # Copiar DLLs necessárias
        Write-Host "Copiando DLLs necessárias..." -ForegroundColor Yellow
        $dllSource = "$msys2Path\mingw64\bin"
        $requiredDlls = @(
            "libgtk-4-1.dll",
            "libgobject-2.0-0.dll",
            "libglib-2.0-0.dll",
            "libcairo-2.dll",
            "libpango-1.0-0.dll",
            "libpangocairo-1.0-0.dll",
            "libgdk_pixbuf-2.0-0.dll",
            "libgio-2.0-0.dll",
            "libgmodule-2.0-0.dll",
            "libgthread-2.0-0.dll",
            "libintl-8.dll",
            "libwinpthread-1.dll",
            "libgcc_s_seh-1.dll",
            "libstdc++-6.dll",
            "zlib1.dll"
        )
        
        $copiedDlls = 0
        foreach ($dll in $requiredDlls) {
            $dllPath = Join-Path $dllSource $dll
            if (Test-Path $dllPath) {
                Copy-Item $dllPath $binDir -Force
                $copiedDlls++
            }
        }
        
        Write-Host "✓ $copiedDlls DLLs copiadas para o diretório de output" -ForegroundColor Green
        
        # Executar se solicitado
        if ($Run) {
            Write-Host "`nExecutando aplicação..." -ForegroundColor Yellow
            Write-Host "Pressione Ctrl+C para interromper" -ForegroundColor Gray
            & $outputPath
        }
        
    } else {
        Write-Host "✗ Erro na compilação!" -ForegroundColor Red
        exit $process.ExitCode
    }
    
} catch {
    Write-Host "✗ Erro ao executar o comando de compilação: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Build concluído!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Executável: $outputPath" -ForegroundColor Yellow
Write-Host "Para executar: .\build\bin\gtk4-app.exe" -ForegroundColor Yellow
Write-Host "Para executar automaticamente: .\build.ps1 -Run" -ForegroundColor Yellow
Write-Host "`nTipos de build disponíveis:" -ForegroundColor Cyan
Write-Host "  Debug       - Build com símbolos de debug (padrão, mostra terminal)" -ForegroundColor Gray
Write-Host "  Release     - Build otimizado para produção (GUI, sem terminal)" -ForegroundColor Gray
Write-Host "  Production  - Build final otimizado (GUI, sem terminal, menor tamanho)" -ForegroundColor Gray
Write-Host "`nExemplo: .\build.ps1 -BuildType production -Run" -ForegroundColor Yellow
