import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../data/datasources/location_datasource.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/get_current_location.dart';

final locationDataSourceProvider = Provider<LocationDataSource>(
  (_) => StubLocationDataSource(),
);

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepositoryImpl(ref.watch(locationDataSourceProvider)),
);

final getCurrentLocationProvider = Provider(
  (ref) => GetCurrentLocation(ref.watch(locationRepositoryProvider)),
);

final currentLocationProvider = FutureProvider<Result<Location>>((ref) {
  return ref.watch(getCurrentLocationProvider).call();
});
