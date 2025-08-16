import 'environment.dart';

class TecaAIConfig {
  // Configuração da URL da API TecaAI - agora centralizada
  static String get baseUrl => EnvironmentConfig.tecaaiBaseUrl;
  
  // Timeout para requisições - agora centralizado
  static int get requestTimeout => EnvironmentConfig.tecaaiRequestTimeout;
  
  // Headers padrão
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // Endpoints específicos do TecaAI
  static const String healthEndpoint = '/health';
  static const String askEndpoint = '/ask';
  static const String locateEndpoint = '/locate';
  static const String controlEndpoint = '/control';
  static const String itemInfoEndpoint = '/item-info';
  static const String historyEndpoint = '/history';
  static const String statsEndpoint = '/stats';
  static const String itemsEndpoint = '/items';

  // Métodos utilitários para construir URLs completas
  static String getHealthUrl() => EnvironmentConfig.getTecaAIUrl(healthEndpoint);
  static String getAskUrl() => EnvironmentConfig.getTecaAIUrl(askEndpoint);
  static String getLocateUrl() => EnvironmentConfig.getTecaAIUrl(locateEndpoint);
  static String getControlUrl() => EnvironmentConfig.getTecaAIUrl(controlEndpoint);
  static String getItemInfoUrl() => EnvironmentConfig.getTecaAIUrl(itemInfoEndpoint);
  static String getHistoryUrl() => EnvironmentConfig.getTecaAIUrl(historyEndpoint);
  static String getStatsUrl() => EnvironmentConfig.getTecaAIUrl(statsEndpoint);
  static String getItemsUrl() => EnvironmentConfig.getTecaAIUrl(itemsEndpoint);
  static String getItemUrl(int itemId) => EnvironmentConfig.getTecaAIUrl('$itemsEndpoint/$itemId');

  // Comandos pré-definidos para facilitar o uso
  static const Map<String, String> predefinedCommands = {
    'ligar_luz': 'ligue a luz',
    'desligar_luz': 'desligue a luz',
    'modo_festa_on': 'ligue modo festa',
    'modo_festa_off': 'desligue modo festa',
    'alarme_fumaca': 'os alarmes de fumaça foram acionados',
  };
}
