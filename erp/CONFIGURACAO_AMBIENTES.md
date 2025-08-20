# 🔧 Configuração de Ambientes - ByLAB ERP

## 📋 Visão Geral

O sistema agora possui uma **configuração centralizada** que permite alterar todas as URLs e configurações de uma única localização, facilitando a mudança entre ambientes de desenvolvimento, produção e local.

## 🏗️ Arquitetura da Configuração

### Estrutura de Arquivos
```
erp/lib/config/
├── environment.dart          # Configurações de ambiente (desenvolvimento, produção, local)
├── api_config.dart          # Configurações da API principal
├── tecaai_config.dart       # Configurações da API TecaAI (IA educacional)
└── app_config.dart          # Configuração centralizada do aplicativo
```

## 🌍 Ambientes Disponíveis

### 1. **Desenvolvimento** (`Environment.development`)
- **API Base URL**: `http://192.168.18.15:3000`
- **TecaAI Base URL**: `http://192.168.18.15:5001`
- **Debug Mode**: ✅ Ativado
- **Log Level**: Debug
- **Analytics**: ❌ Desativado

### 2. **Produção** (`Environment.production`)
- **API Base URL**: `https://seu-dominio.com`
- **TecaAI Base URL**: `https://ia.seu-dominio.com`
- **Debug Mode**: ❌ Desativado
- **Log Level**: Error
- **Analytics**: ✅ Ativado

### 3. **Local** (`Environment.local`)
- **API Base URL**: `http://localhost:3000`
- **TecaAI Base URL**: `http://localhost:5001`
- **Debug Mode**: ✅ Ativado
- **Log Level**: Verbose
- **Analytics**: ❌ Desativado

## ⚙️ Como Alterar o Ambiente

### Método 1: Alterar no Código
```dart
// No arquivo erp/lib/main.dart
void main() async {
  // ... outras inicializações ...
  
  // Alterar para o ambiente desejado
  EnvironmentConfig.setEnvironment(Environment.production); // ou .development ou .local
  
  // ... resto do código ...
}
```

### Método 2: Usar Variáveis de Ambiente (Recomendado)
```dart
// No arquivo erp/lib/config/environment.dart
class EnvironmentConfig {
  static Environment _environment = Environment.local;

  static void setEnvironment(Environment env) {
    // Você pode ler de uma variável de ambiente aqui
    final envVar = const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    switch (envVar) {
      case 'production':
        _environment = Environment.production;
        break;
      case 'local':
        _environment = Environment.local;
        break;
      default:
        _environment = Environment.development;
    }
  }
}
```

## 🚀 Como Executar com Diferentes Ambientes

### Desenvolvimento
```bash
flutter run --dart-define=ENVIRONMENT=development
```

### Produção
```bash
flutter run --dart-define=ENVIRONMENT=production
```

### Local
```bash
flutter run --dart-define=ENVIRONMENT=local
```

## 📱 URLs Configuradas

### API Principal
- **Auth**: `/auth`
- **Users**: `/users`
- **Students**: `/students`
- **Teachers**: `/teachers`
- **Classes**: `/classes`
- **Subjects**: `/subjects`
- **Grades**: `/grades`
- **Attendance**: `/attendance`
- **Assignments**: `/assignments`
- **Chat**: `/chat`
- **Enrollments**: `/enrollments`
- **Lessons**: `/lessons`
- **Grade Types**: `/grade-types`
- **Grade Periods**: `/grade-periods`

### TecaAI (IA Educacional)
- **Health Check**: `/health`
- **Ask Question**: `/ask`
- **Locate Item**: `/locate`
- **Control Device**: `/control`
- **Item Info**: `/item-info`
- **History**: `/history`
- **Stats**: `/stats`
- **Items**: `/items`

## 🔍 Verificar Configurações Atuais

O app imprime automaticamente as configurações atuais no console ao iniciar:

```
🔧 === CONFIGURAÇÕES ATUAIS DO APP ===
🌍 Ambiente: DEVELOPMENT
🔗 API Base URL: http://192.168.18.15:3000
🤖 TecaAI Base URL: http://192.168.18.15:5001
📁 Uploads Base URL: http://192.168.18.15:3000
⏱️ API Timeout: 30s
⏱️ TecaAI Timeout: 30s
📏 Max File Size: 10.0MB
🔒 HTTPS: false
🌐 CORS: true
🐛 Debug Mode: true
📝 Log Level: debug
📊 Analytics: false
🚨 Crash Reporting: false
=====================================
```

## ✅ Validação de Configurações

O sistema valida automaticamente as configurações ao iniciar e reporta erros:

```dart
final configErrors = AppConfig.validateConfig();
if (configErrors.isNotEmpty) {
  print('❌ ERROS DE CONFIGURAÇÃO:');
  for (final error in configErrors) {
    print('   - $error');
  }
}
```

## 🛠️ Personalização

### Adicionar Novo Ambiente
```dart
// No arquivo erp/lib/config/environment.dart
enum Environment { development, production, local, staging }

// Adicionar configurações para o novo ambiente
static String get apiBaseUrl {
  switch (_environment) {
    case Environment.development:
      return 'http://192.168.18.15:3000';
    case Environment.production:
      return 'https://seu-dominio.com';
    case Environment.local:
      return 'http://localhost:3000';
    case Environment.staging:
      return 'https://staging.seu-dominio.com';
  }
}
```

### Adicionar Nova Configuração
```dart
// No arquivo erp/lib/config/environment.dart
static bool get enableFeatureFlag {
  switch (_environment) {
    case Environment.development:
      return true;
    case Environment.production:
      return false;
    case Environment.local:
      return true;
  }
}
```

## 🔒 Segurança

- **Desenvolvimento/Local**: HTTP (sem criptografia)
- **Produção**: HTTPS obrigatório
- **Senhas**: Sempre criptografadas com bcrypt
- **JWT**: Tokens de autenticação seguros

## 📞 Suporte

Para dúvidas sobre configuração:
1. Verifique o console do app para configurações atuais
2. Consulte este documento
3. Verifique os arquivos de configuração em `erp/lib/config/`

## 🎯 Benefícios da Nova Arquitetura

✅ **Centralização**: Todas as configurações em um local
✅ **Flexibilidade**: Fácil mudança entre ambientes
✅ **Manutenibilidade**: Código mais limpo e organizado
✅ **Debug**: Configurações visíveis no console
✅ **Validação**: Verificação automática de configurações
✅ **Escalabilidade**: Fácil adição de novos ambientes
