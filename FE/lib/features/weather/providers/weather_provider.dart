import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather_model.dart';
import '../repositories/weather_repository.dart';

class WeatherLatLng {
  const WeatherLatLng(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherLatLng && lat == other.lat && lng == other.lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => WeatherRepository(),
);

final currentWeatherByLatLngProvider =
    FutureProvider.family<WeatherModel, WeatherLatLng>((ref, point) {
  return ref.watch(weatherRepositoryProvider).getCurrentWeatherByLatLng(
        lat: point.lat,
        lng: point.lng,
      );
});
