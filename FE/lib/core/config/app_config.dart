import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get baseUrl {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (apiBaseUrl.isNotEmpty) return apiBaseUrl;

    const legacyBaseUrl = String.fromEnvironment('BASE_URL');
    if (legacyBaseUrl.isNotEmpty) return legacyBaseUrl;

    final envUrl = dotenv.env['API_BASE_URL'] ?? dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    // Use 10.0.2.2 for Android Emulator to access host machine's localhost
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://localhost:8080';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
