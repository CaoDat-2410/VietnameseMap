import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../map/domain/entities/administrative_unit.dart';
import '../../../map/domain/entities/unit_level.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../data/datasources/weather_remote_datasource.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/entities/current_weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/usecases/get_current_weather.dart';

final weatherDataSourceProvider = Provider<WeatherRemoteDataSource>(
  (ref) => WeatherRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);

final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => WeatherRepositoryImpl(ref.watch(weatherDataSourceProvider)),
);

final getCurrentWeatherProvider = Provider(
  (ref) => GetCurrentWeather(ref.watch(weatherRepositoryProvider)),
);

typedef LatLng = ({double lat, double lng});

final weatherByCoordinatesProvider =
    FutureProvider.family<Result<CurrentWeather>, LatLng>((ref, coords) {
  return ref.watch(getCurrentWeatherProvider).call(coords.lat, coords.lng);
});

enum WeatherLocationSourceType {
  currentLocation,
  province,
  district,
  ward,
  mapTap,
}

class SelectedWeatherLocation {
  const SelectedWeatherLocation({
    required this.displayName,
    this.provinceName,
    this.districtName,
    this.wardName,
    required this.lat,
    required this.lng,
    required this.sourceType,
    this.code,
    required this.selectedAt,
  });

  final String displayName;
  final String? provinceName;
  final String? districtName;
  final String? wardName;
  final double lat;
  final double lng;
  final WeatherLocationSourceType sourceType;
  final String? code;
  final DateTime selectedAt;

  LatLng get coords => (lat: lat, lng: lng);
}

class SelectedWeatherSnapshot {
  const SelectedWeatherSnapshot({
    required this.location,
    required this.weather,
  });

  final SelectedWeatherLocation location;
  final CurrentWeather weather;
}

final selectedWeatherLocationProvider =
    StateProvider<SelectedWeatherLocation?>((ref) => null);

final activeWeatherLocationProvider =
    FutureProvider<Result<SelectedWeatherLocation>>((ref) async {
  final selected = ref.watch(selectedWeatherLocationProvider);
  if (selected != null) return Ok(selected);

  final currentResult = await ref.watch(currentLocationProvider.future);
  return currentResult.when<Future<Result<SelectedWeatherLocation>>>(
    ok: (location) async {
      final geoRepository = ref.read(geoRepositoryProvider);
      final reverseResult = await geoRepository.reverseGeocode(
        location.latitude,
        location.longitude,
      );

      String displayName = 'Vị trí hiện tại';
      String? provinceName;
      String? districtName;
      String? wardName;
      String? code;

      if (reverseResult.isOk) {
        final names = await resolveAdministrativeNames(
          ref,
          reverseResult.valueOrThrow,
        );
        provinceName = names.provinceName;
        districtName = names.districtName;
        wardName = names.wardName;
        code = names.code;
        displayName = buildWeatherDisplayName(
          provinceName: provinceName,
          districtName: districtName,
          wardName: wardName,
          fallback: 'Vị trí hiện tại',
        );
      }

      return Ok(
        SelectedWeatherLocation(
          displayName: displayName,
          provinceName: provinceName,
          districtName: districtName,
          wardName: wardName,
          lat: location.latitude,
          lng: location.longitude,
          sourceType: WeatherLocationSourceType.currentLocation,
          code: code,
          selectedAt: DateTime.now(),
        ),
      );
    },
    err: (failure) async => Err(failure),
  );
});

final selectedWeatherProvider =
    FutureProvider<Result<SelectedWeatherSnapshot>>((ref) async {
  final timer = Timer(const Duration(minutes: 10), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);

  final locationResult = await ref.watch(activeWeatherLocationProvider.future);
  return locationResult.when<Future<Result<SelectedWeatherSnapshot>>>(
    ok: (location) async {
      if (!_isValidCoordinate(location.lat, location.lng)) {
        return const Err(
          ValidationFailure('Tọa độ thời tiết không hợp lệ.'),
        );
      }

      final weatherResult = await ref
          .watch(getCurrentWeatherProvider)
          .call(location.lat, location.lng);
      return weatherResult.when(
        ok: (weather) => Ok(
          SelectedWeatherSnapshot(location: location, weather: weather),
        ),
        err: (failure) => Err(failure),
      );
    },
    err: (failure) async => Err(failure),
  );
});

bool _isValidCoordinate(double lat, double lng) {
  return lat.isFinite &&
      lng.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180;
}

typedef AdministrativeNames = ({
  String? provinceName,
  String? districtName,
  String? wardName,
  String? code,
});

Future<AdministrativeNames> resolveAdministrativeNames(
  Ref ref,
  AdministrativeUnit unit,
) async {
  final repo = ref.read(geoRepositoryProvider);
  AdministrativeUnit? currentUnit = unit;
  String? provinceName;
  String? districtName;
  String? wardName;
    final String code = unit.code;

  while (currentUnit != null) {
    final cu = currentUnit;
    switch (cu.level) {
      case UnitLevel.province:
        provinceName = cu.name;
        break;
      case UnitLevel.district:
        districtName = cu.name;
        break;
      case UnitLevel.ward:
        wardName = cu.name;
        break;
    }

    if (cu.parentCode == null) break;
    final parentResult = await repo.getUnitByCode(cu.parentCode!);
    currentUnit = parentResult.when<AdministrativeUnit?>(
      ok: (parent) => parent,
      err: (_) => null,
    );
  }

  return (
    provinceName: provinceName,
    districtName: districtName,
    wardName: wardName,
    code: code,
  );
}

String buildWeatherDisplayName({
  String? provinceName,
  String? districtName,
  String? wardName,
  required String fallback,
}) {
  final parts = <String>[
    if (wardName != null && wardName.trim().isNotEmpty) wardName,
    if (districtName != null && districtName.trim().isNotEmpty) districtName,
    if (provinceName != null && provinceName.trim().isNotEmpty) provinceName,
  ];
  if (parts.isEmpty) return fallback;
  return parts.join(', ');
}
