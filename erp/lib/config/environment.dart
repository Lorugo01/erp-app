import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment { development, production, local }

class EnvironmentConfig {
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String _env(String key, String fallback) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) return fallback;
    return value;
  }

  static int _envInt(String key, int fallback) {
    return int.tryParse(_env(key, fallback.toString())) ?? fallback;
  }

  static bool _envBool(String key, bool fallback) {
    final value = _env(key, fallback.toString()).toLowerCase();
    if (value == 'true' || value == '1' || value == 'yes') return true;
    if (value == 'false' || value == '0' || value == 'no') return false;
    return fallback;
  }

  static Environment get environment {
    switch (_env('ENVIRONMENT', 'local').toLowerCase()) {
      case 'development':
      case 'dev':
        return Environment.development;
      case 'production':
      case 'prod':
        return Environment.production;
      default:
        return Environment.local;
    }
  }

  static String get apiBaseUrl => _env('API_BASE_URL', 'http://localhost:3000');

  static String get tecaaiBaseUrl {
    final base = _stripTrailingSlash(
      _env('TECAAI_BASE_URL', 'http://localhost:5010'),
    );
    final prefix = _env('TECAAI_PATH_PREFIX', '');
    if (prefix.isEmpty) return base;
    final normalized = prefix.startsWith('/') ? prefix : '/$prefix';
    return '$base$normalized';
  }

  static String _stripTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  static String get uploadsBaseUrl =>
      _env('UPLOADS_BASE_URL', apiBaseUrl);

  static int get apiRequestTimeout => _envInt('API_REQUEST_TIMEOUT', 30);

  static int get tecaaiRequestTimeout => _envInt('TECAAI_REQUEST_TIMEOUT', 30);

  static int get maxFileSize => _envInt('MAX_FILE_SIZE', 10 * 1024 * 1024);

  static bool get enableHttps => _envBool('ENABLE_HTTPS', environment == Environment.production);

  static bool get enableCors => _envBool('ENABLE_CORS', true);

  static bool get isDevelopment => environment == Environment.development;

  static bool get isProduction => environment == Environment.production;

  static bool get isLocal => environment == Environment.local;

  static bool get debugMode => _envBool('DEBUG_MODE', !isProduction);

  static String get logLevel => _env('LOG_LEVEL', isProduction ? 'error' : 'debug');

  static bool get enableAnalytics => _envBool('ENABLE_ANALYTICS', isProduction);

  static bool get enableCrashReporting =>
      _envBool('ENABLE_CRASH_REPORTING', isProduction);

  static String getApiUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }

  static String getUploadUrl(String filePath) {
    if (filePath.startsWith('http')) return filePath;
    return '$uploadsBaseUrl$filePath';
  }

  static String getTecaAIUrl(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$tecaaiBaseUrl$path';
  }
}
