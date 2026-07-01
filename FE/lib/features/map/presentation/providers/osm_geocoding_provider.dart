import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/repositories/osm_geocoding_repository.dart';

final dioClientProvider = Provider<DioClient>((_) => DioClient());

final osmGeocodingRepositoryProvider = Provider<OsmGeocodingRepository>(
  (ref) => OsmGeocodingRepository(ref.watch(dioClientProvider)),
);

/// On-demand geocoding for the given school UIDs.
/// Coordinates are returned for the current request only — not persisted.
final schoolGeocodeProvider = FutureProvider.family<List<SchoolGeocode>, List<String>>(
  (ref, schoolUids) async {
    if (schoolUids.isEmpty) return const [];
    final repo = ref.watch(osmGeocodingRepositoryProvider);
    return repo.geocodeSchools(schoolUids);
  },
);
