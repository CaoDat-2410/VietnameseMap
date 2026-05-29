import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get baseUrl {
    const fromDefine = String.fromEnvironment('BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['BASE_URL'] ?? 'http://localhost:8080';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
