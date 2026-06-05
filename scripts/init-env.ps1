# Primeira vez: cria .env da raiz (API) e erp/.env (Flutter)
# Uso: .\scripts\init-env.ps1

$root = Split-Path $PSScriptRoot -Parent
$apiEnv = Join-Path $root ".env"
$apiExample = Join-Path $root ".env.example"
$flutterEnv = Join-Path $root "erp\.env"
$flutterExample = Join-Path $root "erp\.env.example"

if (Test-Path $apiEnv) {
    Write-Host ".env ja existe na raiz: $apiEnv" -ForegroundColor Yellow
} elseif (Test-Path $apiExample) {
    Copy-Item $apiExample $apiEnv
    Write-Host ".env criado: $apiEnv" -ForegroundColor Green
} else {
    Write-Host "Erro: .env.example nao encontrado na raiz" -ForegroundColor Red
    exit 1
}

if (Test-Path $flutterEnv) {
    Write-Host "erp/.env ja existe" -ForegroundColor Yellow
} elseif (Test-Path $flutterExample) {
    Copy-Item $flutterExample $flutterEnv
    Write-Host "erp/.env criado" -ForegroundColor Green
} else {
    Write-Host "Erro: erp/.env.example nao encontrado" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Edite os arquivos e rode:" -ForegroundColor Cyan
Write-Host "  API:    cd bylab-new-api ; npm run dev" -ForegroundColor White
Write-Host "  Mobile: cd erp ; flutter run" -ForegroundColor White
