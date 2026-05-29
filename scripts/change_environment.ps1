# Altera ambiente no .env da RAIZ do projeto
# Uso: .\scripts\change_environment.ps1 [local|development|production]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "production", "local")]
    [string]$Environment
)

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"

if (-not (Test-Path $envFile)) {
    Copy-Item (Join-Path $root ".env.example") $envFile
    Write-Host ".env criado na raiz do projeto" -ForegroundColor Yellow
}

$configs = @{
    "development" = @{
        "apiBaseUrl" = "http://192.168.18.15:3000"
        "tecaaiBaseUrl" = "http://192.168.18.15:5001"
        "uploadsBaseUrl" = "http://192.168.18.15:3000"
        "enableHttps" = "false"
        "debugMode" = "true"
        "logLevel" = "debug"
    }
    "production" = @{
        "apiBaseUrl" = "http://SEU_IP_OU_DOMINIO:3000"
        "tecaaiBaseUrl" = "http://SEU_IP_OU_DOMINIO:5001"
        "uploadsBaseUrl" = "http://SEU_IP_OU_DOMINIO:3000"
        "enableHttps" = "false"
        "debugMode" = "false"
        "logLevel" = "error"
    }
    "local" = @{
        "apiBaseUrl" = "http://localhost:3000"
        "tecaaiBaseUrl" = "http://localhost:5001"
        "uploadsBaseUrl" = "http://localhost:3000"
        "enableHttps" = "false"
        "debugMode" = "true"
        "logLevel" = "verbose"
    }
}

$config = $configs[$Environment]

function Set-EnvValue {
    param([string]$Key, [string]$Value)
    $content = Get-Content $envFile -Raw -Encoding UTF8
    if ($content -match "(?m)^$Key=") {
        $content = $content -replace "(?m)^$Key=.*", "$Key=$Value"
    } else {
        $content += "`n$Key=$Value"
    }
    Set-Content $envFile $content.TrimEnd() -Encoding UTF8 -NoNewline
}

Set-EnvValue "ENVIRONMENT" $Environment
Set-EnvValue "API_BASE_URL" $config.apiBaseUrl
Set-EnvValue "TECAAI_BASE_URL" $config.tecaaiBaseUrl
Set-EnvValue "UPLOADS_BASE_URL" $config.uploadsBaseUrl
Set-EnvValue "ENABLE_HTTPS" $config.enableHttps
Set-EnvValue "DEBUG_MODE" $config.debugMode
Set-EnvValue "LOG_LEVEL" $config.logLevel

& (Join-Path $PSScriptRoot "sync-env.ps1")

Write-Host "Ambiente alterado para $Environment (erp-app/.env)" -ForegroundColor Green
