import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/features/weather/models/weather_model.dart';
import 'package:vietnamese_map/features/weather/providers/weather_provider.dart';
import 'package:vietnamese_map/features/weather/repositories/weather_repository.dart';
import 'package:vietnamese_map/features/weather/utils/weather_date_time_formatter.dart';

void main() {
  test('WeatherModel parses WeatherAPI current response', () {
    final weather = WeatherModel.fromJson({
      'location': {
        'name': 'Biên Hòa',
        'region': 'Đồng Nai',
        'country': 'Vietnam',
        'localtime': '2026-06-20 14:30',
      },
      'current': {
        'temp_c': 31,
        'feelslike_c': 34,
        'condition': {
          'text': 'Có mây',
          'icon': '//cdn.weatherapi.com/weather/64x64/day/116.png',
        },
        'humidity': 78,
        'wind_kph': 5,
        'cloud': 60,
        'uv': 7,
        'last_updated': '2026-06-20 14:30',
      },
    });

    expect(weather.locationName, 'Biên Hòa');
    expect(weather.region, 'Đồng Nai');
    expect(weather.tempC, 31);
    expect(weather.feelslikeC, 34);
    expect(weather.conditionText, 'Có mây');
    expect(weather.conditionIcon, startsWith('https://'));
    expect(weather.humidity, 78);
    expect(weather.windKph, 5);
    expect(weather.cloud, 60);
    expect(weather.uv, 7);
  });

  test('formatWeatherDateTime formats WeatherAPI timestamps', () {
    expect(
      formatWeatherDateTime('2026-06-20 14:30'),
      '20/06/2026 14:30',
    );
    expect(formatWeatherDateTime(null), 'N/A');
  });

  test('WeatherLatLng supports provider family equality', () {
    expect(
      const WeatherLatLng(10.95, 106.82),
      const WeatherLatLng(10.95, 106.82),
    );
  });

  test('repository reports missing WEATHER_API_KEY clearly', () async {
    if (const String.fromEnvironment('WEATHER_API_KEY').isNotEmpty) return;

    expect(
      () => WeatherRepository().getCurrentWeatherByLatLng(
        lat: 10.95,
        lng: 106.82,
      ),
      throwsA(
        isA<WeatherConfigurationException>().having(
          (error) => error.toString(),
          'message',
          contains('Missing WEATHER_API_KEY'),
        ),
      ),
    );
  });

  test('repository loads live weather when dart-define key is provided',
      () async {
    if (const String.fromEnvironment('WEATHER_API_KEY').isEmpty) return;

    final weather = await WeatherRepository().getCurrentWeatherByLatLng(
      lat: 10.95,
      lng: 106.82,
    );

    expect(weather.locationName, isNotEmpty);
    expect(weather.conditionText, isNotEmpty);
    expect(weather.lastUpdated, isNotEmpty);
  });
}
