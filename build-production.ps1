# Script rápido para build de produção
# Este script compila a aplicação para distribuição final

Write-Host "Compilando para produção..." -ForegroundColor Cyan
& "$PSScriptRoot\build.ps1" -BuildType production -Clean

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Build de produção concluída!" -ForegroundColor Green
    Write-Host "Aplicação está pronta para distribuição em:" -ForegroundColor Yellow
    Write-Host "  .\build\bin\gtk4-app.exe" -ForegroundColor White
    Write-Host "`nCaracterísticas da build de produção:" -ForegroundColor Cyan
    Write-Host "  ✓ Otimizada para velocidade (-O ReleaseFast)" -ForegroundColor Green
    Write-Host "  ✓ Símbolos de debug removidos (-fstrip)" -ForegroundColor Green
    Write-Host "  ✓ Executa como aplicação GUI (--subsystem windows)" -ForegroundColor Green
    Write-Host "  ✓ Não abre terminal no fundo" -ForegroundColor Green
    Write-Host "  ✓ Menor tamanho de arquivo" -ForegroundColor Green
    Write-Host "`nPara executar: Clique duplo no arquivo .exe ou execute .\build\bin\gtk4-app.exe" -ForegroundColor Yellow
} else {
    Write-Host "✗ Erro na build de produção!" -ForegroundColor Red
    exit 1
}