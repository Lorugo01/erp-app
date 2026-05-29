# Redireciona para o script na raiz do projeto
& (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "scripts\change_environment.ps1") @args
