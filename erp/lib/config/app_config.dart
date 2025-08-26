import 'environment.dart';
import "package:flutter/material.dart";

/// Configuração centralizada do aplicativo
///
/// Este arquivo centraliza todas as configurações importantes do app,
/// permitindo fácil mudança entre ambientes de desenvolvimento, produção e local.
class AppConfig {
  // Configurações de ambiente
  static Environment get environment => EnvironmentConfig.environment;
  static bool get isDevelopment => EnvironmentConfig.isDevelopment;
  static bool get isProduction => EnvironmentConfig.isProduction;
  static bool get isLocal => EnvironmentConfig.isLocal;

  // URLs das APIs
  static String get apiBaseUrl => EnvironmentConfig.apiBaseUrl;
  static String get tecaaiBaseUrl => EnvironmentConfig.tecaaiBaseUrl;
  static String get uploadsBaseUrl => EnvironmentConfig.uploadsBaseUrl;

  // Timeouts
  static Duration get apiTimeout => const Duration(seconds: 30);
  static Duration get tecaaiTimeout => const Duration(seconds: 30);

  // Configurações de upload
  static int get maxFileSize => EnvironmentConfig.maxFileSize;

  // Configurações de rede
  static bool get enableHttps => EnvironmentConfig.enableHttps;
  static bool get enableCors => EnvironmentConfig.enableCors;

  // Métodos utilitários para URLs
  static String getApiUrl(String endpoint) =>
      EnvironmentConfig.getApiUrl(endpoint);
  static String getUploadUrl(String filePath) =>
      EnvironmentConfig.getUploadUrl(filePath);
  static String getTecaAIUrl(String endpoint) =>
      EnvironmentConfig.getTecaAIUrl(endpoint);

  // Configurações específicas por ambiente
  static Map<String, dynamic> get environmentSpecificConfig {
    switch (environment) {
      case Environment.development:
        return {
          'debugMode': true,
          'logLevel': 'debug',
          'enableAnalytics': false,
          'enableCrashReporting': false,
        };
      case Environment.production:
        return {
          'debugMode': false,
          'logLevel': 'error',
          'enableAnalytics': true,
          'enableCrashReporting': true,
        };
      case Environment.local:
        return {
          'debugMode': true,
          'logLevel': 'verbose',
          'enableAnalytics': false,
          'enableCrashReporting': false,
        };
    }
  }

  // Configurações de debug
  static bool get debugMode => environmentSpecificConfig['debugMode'] ?? false;
  static String get logLevel => environmentSpecificConfig['logLevel'] ?? 'info';
  static bool get enableAnalytics =>
      environmentSpecificConfig['enableAnalytics'] ?? false;
  static bool get enableCrashReporting =>
      environmentSpecificConfig['enableCrashReporting'] ?? false;

  // Método para imprimir configurações atuais (útil para debug)
  static void printCurrentConfig() {
    debugPrint('🔧 === CONFIGURAÇÕES ATUAIS DO APP ===');
    debugPrint('🌍 Ambiente: ${environment.name.toUpperCase()}');
    debugPrint('🔗 API Base URL: $apiBaseUrl');
    debugPrint('🤖 TecaAI Base URL: $tecaaiBaseUrl');
    debugPrint('📁 Uploads Base URL: $uploadsBaseUrl');
    debugPrint('⏱️ API Timeout: ${apiTimeout.inSeconds}s');
    debugPrint('⏱️ TecaAI Timeout: ${tecaaiTimeout.inSeconds}s');
    debugPrint(
      '📏 Max File Size: ${(maxFileSize / (1024 * 1024)).toStringAsFixed(1)}MB',
    );
    debugPrint('🔒 HTTPS: $enableHttps');
    debugPrint('🌐 CORS: $enableCors');
    debugPrint('🐛 Debug Mode: $debugMode');
    debugPrint('📝 Log Level: $logLevel');
    debugPrint('📊 Analytics: $enableAnalytics');
    debugPrint('🚨 Crash Reporting: $enableCrashReporting');
    debugPrint('=====================================');
  }

  // Método para validar configurações
  static List<String> validateConfig() {
    final errors = <String>[];

    if (apiBaseUrl.isEmpty) {
      errors.add('API Base URL não pode estar vazia');
    }
    if (tecaaiBaseUrl.isEmpty) {
      errors.add('TecaAI Base URL não pode estar vazia');
    }
    if (uploadsBaseUrl.isEmpty) {
      errors.add('Uploads Base URL não pode estar vazia');
    }
    if (apiTimeout.inSeconds <= 0) {
      errors.add('API Request Timeout deve ser maior que 0');
    }
    if (tecaaiTimeout.inSeconds <= 0) {
      errors.add('TecaAI Request Timeout deve ser maior que 0');
    }
    if (maxFileSize <= 0) {
      errors.add('Max File Size deve ser maior que 0');
    }

    return errors;
  }
}
