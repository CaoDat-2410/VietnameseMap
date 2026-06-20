import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/features/weather/models/weather_model.dart';
import 'package:vietnamese_map/features/weather/providers/weather_provider.dart';
import 'package:vietnamese_map/features/weather/widgets/weather_api_card.dart';

void main() {
  testWidgets('WeatherApiCard renders friendly weather values', (tester) async {
    const point = WeatherLatLng(10.95, 106.82);
    const weather = WeatherModel(
      locationName: 'Biên Hòa',
      region: 'Đồng Nai',
      country: 'Vietnam',
      localtime: '2026-06-20 14:30',
      tempC: 31,
      feelslikeC: 34,
      conditionText: 'Có mây',
      conditionIcon: '',
      humidity: 78,
      windKph: 5,
      cloud: 60,
      uv: 7,
      lastUpdated: '2026-06-20 14:30',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentWeatherByLatLngProvider(point).overrideWith(
            (ref) async => weather,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WeatherApiCard(
              point: point,
              title: 'THPT Biên Hòa',
              subtitle: 'Đồng Nai',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('THPT Biên Hòa'), findsOneWidget);
    expect(find.text('31°C'), findsOneWidget);
    expect(find.text('Có mây'), findsOneWidget);
    expect(find.text('💧 Độ ẩm: 78%'), findsOneWidget);
    expect(find.text('🌬 Gió: 5.0 km/h'), findsOneWidget);
    expect(find.text('☀ UV: 7.0'), findsOneWidget);
    expect(find.text('Cập nhật: 20/06/2026 14:30'), findsOneWidget);
    expect(find.textContaining('2026-06-20 14:30'), findsNothing);
  });
}
