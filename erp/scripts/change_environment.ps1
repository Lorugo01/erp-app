# Script PowerShell para mudar ambiente do ByLAB ERP
# Uso: .\change_environment.ps1 [development|production|local]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "production", "local")]
    [string]$Environment
)

Write-Host "🔧 === MUDANDO AMBIENTE DO BYLAB ERP ===" -ForegroundColor Cyan

# Verificar se estamos no diretório correto
if (-not (Test-Path "lib\config\environment.dart")) {
    Write-Host "❌ Erro: Execute este script no diretório raiz do projeto Flutter" -ForegroundColor Red
    exit 1
}

# Configurações por ambiente
$configs = @{
    "development" = @{
        "apiBaseUrl" = "http://192.168.18.15:3000"
        "tecaaiBaseUrl" = "http://192.168.18.15:5001"
        "description" = "Desenvolvimento (IP local)"
    }
    "production" = @{
        "apiBaseUrl" = "https://seu-dominio.com"
        "tecaaiBaseUrl" = "https://ia.seu-dominio.com"
        "description" = "Produção (HTTPS)"
    }
    "local" = @{
        "apiBaseUrl" = "http://localhost:3000"
        "tecaaiBaseUrl" = "http://localhost:5001"
        "description" = "Local (localhost)"
    }
}

$config = $configs[$Environment]

Write-Host "🌍 Mudando para ambiente: $Environment" -ForegroundColor Yellow
Write-Host "📝 Descrição: $($config.description)" -ForegroundColor White
Write-Host "🔗 API Base URL: $($config.apiBaseUrl)" -ForegroundColor Green
Write-Host "🤖 TecaAI Base URL: $($config.tecaaiBaseUrl)" -ForegroundColor Green

# Atualizar o arquivo main.dart
$mainFile = "lib\main.dart"
if (Test-Path $mainFile) {
    $content = Get-Content $mainFile -Raw
    $newContent = $content -replace 'EnvironmentConfig\.setEnvironment\(Environment\.[^)]+\)', "EnvironmentConfig.setEnvironment(Environment.$Environment)"
    
    if ($content -ne $newContent) {
        Set-Content $mainFile $newContent -Encoding UTF8
        Write-Host "✅ main.dart atualizado com sucesso" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ main.dart já está configurado para $Environment" -ForegroundColor Blue
    }
} else {
    Write-Host "⚠️ Arquivo main.dart não encontrado" -ForegroundColor Yellow
}

# Executar Flutter clean e get
Write-Host "🧹 Executando Flutter clean..." -ForegroundColor Yellow
flutter clean

Write-Host "📦 Executando Flutter pub get..." -ForegroundColor Yellow
flutter pub get

Write-Host "✅ Ambiente alterado para $Environment com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Para executar o app:" -ForegroundColor Cyan
Write-Host "   flutter run --dart-define=ENVIRONMENT=$Environment" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Para verificar as configurações, execute o app e veja o console" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
