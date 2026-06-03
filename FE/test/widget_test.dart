import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vietnamese_map/core/utils/result.dart';
import 'package:vietnamese_map/features/weather/domain/entities/current_weather.dart';
import 'package:vietnamese_map/features/weather/presentation/pages/weather_page.dart';
import 'package:vietnamese_map/features/weather/presentation/providers/weather_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8080');
  });

  testWidgets('Weather tab renders selected location detail',
      (WidgetTester tester) async {
    final snapshot = SelectedWeatherSnapshot(
      location: SelectedWeatherLocation(
        displayName: 'Hà Nội',
        provinceName: 'Hà Nội',
        lat: 21.0285,
        lng: 105.8542,
        sourceType: WeatherLocationSourceType.currentLocation,
        selectedAt: DateTime(2026, 6, 3),
      ),
      weather: CurrentWeather(
        temperature: 28,
        feelsLike: 30,
        humidity: 78,
        windSpeed: 1.2,
        description: 'Mây rải rác',
        iconCode: '02d',
        locationName: 'Xom Pho',
        timestamp: DateTime(2026, 6, 3, 10),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedWeatherProvider.overrideWith((ref) async => Ok(snapshot)),
        ],
        child: const MaterialApp(home: WeatherPage()),
      ),
    );

    await tester.pump();

    expect(find.text('Thời tiết'), findsOneWidget);
    expect(find.text('Hà Nội'), findsOneWidget);
    expect(find.textContaining('28.0'), findsOneWidget);
    expect(find.text('Xom Pho'), findsNothing);
  });
}
