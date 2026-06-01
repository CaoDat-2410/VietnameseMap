import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/geo_local_datasource.dart';
import '../../data/datasources/geo_remote_datasource.dart';
import '../../data/repositories/geo_repository_impl.dart';
import '../../domain/entities/administrative_unit_summary.dart';
import '../../domain/repositories/geo_repository.dart';
import '../../domain/usecases/get_districts.dart';
import '../../domain/usecases/get_provinces.dart';

final dioClientProvider = Provider<DioClient>((_) => DioClient());

final geoDataSourceProvider = Provider<GeoRemoteDataSource>(
  (ref) => GeoRemoteDataSourceImpl(ref.watch(dioClientProvider)),
);

final geoRepositoryProvider = Provider<GeoRepository>(
  (ref) => GeoRepositoryImpl(ref.watch(geoDataSourceProvider)),
);

final getProvincesProvider = Provider(
  (ref) => GetProvinces(ref.watch(geoRepositoryProvider)),
);

final getDistrictsProvider = Provider(
  (ref) => GetDistricts(ref.watch(geoRepositoryProvider)),
);

final provincesProvider =
    FutureProvider<Result<List<AdministrativeUnitSummary>>>((ref) {
  return ref.watch(getProvincesProvider).call();
});

final districtsProvider =
    FutureProvider.family<Result<List<AdministrativeUnitSummary>>, String>(
        (ref, provinceCode) {
  return ref.watch(getDistrictsProvider).call(provinceCode);
});

final selectedProvinceProvider = StateProvider<AdministrativeUnitSummary?>((ref) => null);

// ---------------------------------------------------------------------------
// Local GeoJSON asset providers (for map boundary overlays)
// ---------------------------------------------------------------------------

final geoLocalDataSourceProvider = Provider<GeoLocalDataSource>(
  (_) => GeoLocalDataSource(),
);

/// Loads all province boundary features from the bundled GeoJSON asset.
/// Returns a list of raw GeoJSON Feature maps for polygon rendering.
final allProvinceBoundariesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final ds = ref.watch(geoLocalDataSourceProvider);
  return ds.getProvinceFeatures();
});

