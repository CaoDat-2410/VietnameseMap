import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
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
