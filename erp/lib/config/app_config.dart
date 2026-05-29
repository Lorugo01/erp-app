import 'environment.dart';
import "package:flutter/material.dart";

/// Configuração centralizada do aplicativo
///
/// Este arquivo centraliza todas as configurações importantes do app,
/// permitindo fácil mudança entre ambientes via arquivo `.env`.
class AppConfig {
  static Environment get environment => EnvironmentConfig.environment;
  static bool get isDevelopment => EnvironmentConfig.isDevelopment;
  static bool get isProduction => EnvironmentConfig.isProduction;
  static bool get isLocal => EnvironmentConfig.isLocal;

  static String get apiBaseUrl => EnvironmentConfig.apiBaseUrl;
  static String get tecaaiBaseUrl => EnvironmentConfig.tecaaiBaseUrl;
  static String get uploadsBaseUrl => EnvironmentConfig.uploadsBaseUrl;

  static int get apiRequestTimeout => EnvironmentConfig.apiRequestTimeout;
  static int get tecaaiRequestTimeout => EnvironmentConfig.tecaaiRequestTimeout;

  static int get maxFileSize => EnvironmentConfig.maxFileSize;

  static bool get enableHttps => EnvironmentConfig.enableHttps;
  static bool get enableCors => EnvironmentConfig.enableCors;

  static String getApiUrl(String endpoint) =>
      EnvironmentConfig.getApiUrl(endpoint);
  static String getUploadUrl(String filePath) =>
      EnvironmentConfig.getUploadUrl(filePath);
  static String getTecaAIUrl(String endpoint) =>
      EnvironmentConfig.getTecaAIUrl(endpoint);

  static bool get debugMode => EnvironmentConfig.debugMode;
  static String get logLevel => EnvironmentConfig.logLevel;
  static bool get enableAnalytics => EnvironmentConfig.enableAnalytics;
  static bool get enableCrashReporting => EnvironmentConfig.enableCrashReporting;

  static void printCurrentConfig() {
    debugPrint('🔧 === CONFIGURAÇÕES ATUAIS DO APP ===');
    debugPrint('🌍 Ambiente: ${environment.name.toUpperCase()}');
    debugPrint('🔗 API Base URL: $apiBaseUrl');
    debugPrint('🤖 TecaAI Base URL: $tecaaiBaseUrl');
    debugPrint('📁 Uploads Base URL: $uploadsBaseUrl');
    debugPrint('⏱️ API Timeout: ${apiRequestTimeout}s');
    debugPrint('⏱️ TecaAI Timeout: ${tecaaiRequestTimeout}s');
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
    if (apiRequestTimeout <= 0) {
      errors.add('API Request Timeout deve ser maior que 0');
    }
    if (tecaaiRequestTimeout <= 0) {
      errors.add('TecaAI Request Timeout deve ser maior que 0');
    }
    if (maxFileSize <= 0) {
      errors.add('Max File Size deve ser maior que 0');
    }

    return errors;
  }
}
