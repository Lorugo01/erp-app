# Garante erp/.env a partir de erp/.env.example (Flutter asset)
# Uso: .\scripts\sync-env.ps1

$root = Split-Path $PSScriptRoot -Parent
$erpDir = Join-Path $root "erp"
$target = Join-Path $erpDir ".env"
$example = Join-Path $erpDir ".env.example"

if (-not (Test-Path $example)) {
    Write-Host "Erro: erp/.env.example nao encontrado" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $target)) {
    Copy-Item $example $target
    Write-Host ".env criado: $target" -ForegroundColor Yellow
} else {
    Write-Host "OK: erp/.env ja existe (nao sobrescrito)" -ForegroundColor Green
}
