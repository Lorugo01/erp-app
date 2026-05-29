# Script PowerShell para mudar ambiente do ByLAB ERP via .env
# Uso: .\scripts\change_environment.ps1 [development|production|local]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "production", "local")]
    [string]$Environment
)

Write-Host "🔧 === MUDANDO AMBIENTE DO BYLAB ERP ===" -ForegroundColor Cyan

if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "📄 .env criado a partir de .env.example" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Erro: arquivo .env não encontrado" -ForegroundColor Red
        exit 1
    }
}

$configs = @{
    "development" = @{
        "apiBaseUrl" = "http://192.168.18.15:3000"
        "tecaaiBaseUrl" = "http://192.168.18.15:5001"
        "uploadsBaseUrl" = "http://192.168.18.15:3000"
        "enableHttps" = "false"
        "debugMode" = "true"
        "logLevel" = "debug"
        "description" = "Desenvolvimento (IP local)"
    }
    "production" = @{
        "apiBaseUrl" = "https://seu-dominio.com"
        "tecaaiBaseUrl" = "https://ia.seu-dominio.com"
        "uploadsBaseUrl" = "https://seu-dominio.com"
        "enableHttps" = "true"
        "debugMode" = "false"
        "logLevel" = "error"
        "description" = "Produção (HTTPS)"
    }
    "local" = @{
        "apiBaseUrl" = "http://localhost:3000"
        "tecaaiBaseUrl" = "http://localhost:5001"
        "uploadsBaseUrl" = "http://localhost:3000"
        "enableHttps" = "false"
        "debugMode" = "true"
        "logLevel" = "verbose"
        "description" = "Local (localhost)"
    }
}

$config = $configs[$Environment]

Write-Host "🌍 Mudando para ambiente: $Environment" -ForegroundColor Yellow
Write-Host "📝 Descrição: $($config.description)" -ForegroundColor White
Write-Host "🔗 API Base URL: $($config.apiBaseUrl)" -ForegroundColor Green

function Set-EnvValue {
    param([string]$Key, [string]$Value)
    $content = Get-Content ".env" -Raw -Encoding UTF8
    if ($content -match "(?m)^$Key=") {
        $content = $content -replace "(?m)^$Key=.*", "$Key=$Value"
    } else {
        $content += "`n$Key=$Value"
    }
    Set-Content ".env" $content.TrimEnd() -Encoding UTF8 -NoNewline
}

Set-EnvValue "ENVIRONMENT" $Environment
Set-EnvValue "API_BASE_URL" $config.apiBaseUrl
Set-EnvValue "TECAAI_BASE_URL" $config.tecaaiBaseUrl
Set-EnvValue "UPLOADS_BASE_URL" $config.uploadsBaseUrl
Set-EnvValue "ENABLE_HTTPS" $config.enableHttps
Set-EnvValue "DEBUG_MODE" $config.debugMode
Set-EnvValue "LOG_LEVEL" $config.logLevel

Write-Host "✅ .env atualizado com sucesso" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Para executar o app:" -ForegroundColor Cyan
Write-Host "   flutter run" -ForegroundColor White
Write-Host ""
Write-Host "💡 Ajuste API_BASE_URL no .env se o IP da sua máquina for diferente" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
