import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  /// Environment mode: 'development', 'staging', or 'production'
  static String get envMode {
    return dotenv.env['ENV_MODE'] ?? 'development';
  }

  /// Check if running in development mode
  static bool get isDevelopment => envMode == 'development';

  /// Check if running in production mode
  static bool get isProduction => envMode == 'production';

  /// Firebase environment: 'dev' or 'prod'
  /// Used to select the correct Firebase project (FirebaseOptions)
  static String get firebaseEnv {
    return dotenv.env['FIREBASE_ENV'] ?? 'dev';
  }

  /// Backend API base URL
  /// Can be set via:
  /// 1. Environment variable: flutter run --dart-define=API_BASE_URL=http://...
  /// 2. .env file: API_BASE_URL=http://...
  /// 3. Falls back to localhost:8080 for development
  static String get baseUrl {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (apiBaseUrl.isNotEmpty) return apiBaseUrl;

    const legacyBaseUrl = String.fromEnvironment('BASE_URL');
    if (legacyBaseUrl.isNotEmpty) return legacyBaseUrl;

    return dotenv.env['API_BASE_URL'] ??
        dotenv.env['BASE_URL'] ??
        'http://localhost:8080';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
