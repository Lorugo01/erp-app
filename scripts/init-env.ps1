# Cria erp-app/.env a partir do exemplo (primeira vez)
# Uso: .\scripts\init-env.ps1

$root = Split-Path $PSScriptRoot -Parent
$target = Join-Path $root ".env"
$example = Join-Path $root ".env.example"

if (Test-Path $target) {
    Write-Host ".env ja existe na raiz: $target" -ForegroundColor Yellow
} elseif (Test-Path $example) {
    Copy-Item $example $target
    Write-Host ".env criado: $target" -ForegroundColor Green
} else {
    Write-Host "Erro: .env.example nao encontrado" -ForegroundColor Red
    exit 1
}

& (Join-Path $PSScriptRoot "sync-env.ps1")

Write-Host ""
Write-Host "Edite erp-app/.env e rode:" -ForegroundColor Cyan
Write-Host "  API:  cd bylab-new-api ; npm run dev" -ForegroundColor White
Write-Host "  Web:  cd erp ; flutter run -d chrome" -ForegroundColor White
