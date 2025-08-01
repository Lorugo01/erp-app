enum Environment { development, production, local }

class EnvironmentConfig {
  static Environment _environment = Environment.local;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static Environment get environment => _environment;

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

  static String get apiUrl {
    return apiBaseUrl;
  }

  // Configurações específicas por ambiente
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isProduction => _environment == Environment.production;
  static bool get isLocal => _environment == Environment.local;
}
