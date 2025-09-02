enum Environment { development, production, local }

class EnvironmentConfig {
  static Environment _environment = Environment.local;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static Environment get environment => _environment;

  // URLs principais da API
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://192.168.18.15:3000';
      case Environment.production:
        return 'https://seu-dominio.com'; // Substitua pelo seu domínio
      case Environment.local:
        return 'http://localhost:3000';
    }
  }

  // URL da API TecaAI (IA educacional)
  static String get tecaaiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://192.168.18.24:5001';
      case Environment.production:
        return 'https://ia.seu-dominio.com'; // Substitua pelo seu domínio
      case Environment.local:
        return 'http://localhost:5001';
    }
  }

  // URL para uploads e arquivos estáticos
  static String get uploadsBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://192.168.18.15:3000';
      case Environment.production:
        return 'https://seu-dominio.com'; // Substitua pelo seu domínio
      case Environment.local:
        return 'http://localhost:3000';
    }
  }

  // Configurações de timeout
  static int get apiRequestTimeout => 30; // segundos
  static int get tecaaiRequestTimeout => 30; // segundos

  // Configurações de upload
  static int get maxFileSize => 10 * 1024 * 1024; // 10MB

  // Configurações de rede
  static bool get enableHttps => _environment == Environment.production;
  static bool get enableCors => true;

  // Configurações específicas por ambiente
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isProduction => _environment == Environment.production;
  static bool get isLocal => _environment == Environment.local;

  // Método para obter URL completa para um endpoint específico
  static String getApiUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }

  // Método para obter URL completa para uploads
  static String getUploadUrl(String filePath) {
    if (filePath.startsWith('http')) return filePath;
    return '$uploadsBaseUrl$filePath';
  }

  // Método para obter URL completa para TecaAI
  static String getTecaAIUrl(String endpoint) {
    return '$tecaaiBaseUrl$endpoint';
  }
}
