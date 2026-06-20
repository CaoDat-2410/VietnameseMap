import 'package:dio/dio.dart';

import '../../../core/config/weather_config.dart';
import '../models/weather_model.dart';

class WeatherConfigurationException implements Exception {
  const WeatherConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WeatherRepository {
  WeatherRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: WeatherConfig.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {'Accept': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<WeatherModel> getCurrentWeatherByLatLng({
    required double lat,
    required double lng,
  }) async {
    if (!WeatherConfig.hasApiKey) {
      throw const WeatherConfigurationException(
        'Missing WEATHER_API_KEY. Run Flutter with '
        '--dart-define=WEATHER_API_KEY=...',
      );
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/current.json',
      queryParameters: {
        'key': WeatherConfig.apiKey,
        'q': '$lat,$lng',
        'aqi': 'no',
        'lang': 'vi',
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('WeatherAPI returned an empty response.');
    }
    return WeatherModel.fromJson(data);
  }
}
