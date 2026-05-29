# Copia erp-app/.env → erp/.env (Flutter exige o asset dentro de erp/)
# Uso: .\scripts\sync-env.ps1

$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root ".env"
$target = Join-Path $root "erp\.env"

if (-not (Test-Path $source)) {
    if (Test-Path (Join-Path $root ".env.example")) {
        Copy-Item (Join-Path $root ".env.example") $source
        Write-Host ".env criado a partir de .env.example" -ForegroundColor Yellow
    } else {
        Write-Host "Erro: .env nao encontrado na raiz do projeto" -ForegroundColor Red
        exit 1
    }
}

Copy-Item $source $target -Force
Write-Host "OK: $source -> $target" -ForegroundColor Green
