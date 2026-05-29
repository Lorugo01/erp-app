# Subir o ERP no navegador (Chrome)
# Usa o .env da RAIZ do projeto (erp-app/.env)

$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& (Join-Path $root "scripts\sync-env.ps1")

Set-Location (Join-Path $root "erp")

Write-Host "Iniciando ByLAB ERP no Chrome..." -ForegroundColor Cyan
flutter pub get
flutter run -d chrome
