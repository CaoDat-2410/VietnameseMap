import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/geojson_utils.dart';
import '../../data/datasources/geo_remote_datasource.dart';
import '../../data/repositories/geo_repository_impl.dart';
import '../../data/models/committee_model.dart';
import '../../domain/entities/administrative_unit_summary.dart';
import '../../domain/repositories/geo_repository.dart';
import '../../domain/usecases/get_provinces.dart';
import '../../domain/usecases/get_communes.dart';
import '../../data/datasources/geo_local_datasource.dart'
    show ProvincePolygonEntry, extractRings, computeCentroid;
import '../../../school/shared/repositories/schools_repository.dart';

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

final getCommunesProvider = Provider(
  (ref) => GetCommunes(ref.watch(geoRepositoryProvider)),
);

final provincesProvider =
    FutureProvider<Result<List<AdministrativeUnitSummary>>>((ref) {
  return ref.watch(getProvincesProvider).call();
});

final communesProvider =
    FutureProvider.family<Result<List<AdministrativeUnitSummary>>, String>(
        (ref, provinceCode) {
  return ref.watch(getCommunesProvider).call(provinceCode);
});

final selectedProvinceProvider =
    StateProvider<AdministrativeUnitSummary?>((ref) => null);
final selectedCommuneProvider =
    StateProvider<({String code, String name, int id})?>((ref) => null);

// ---------------------------------------------------------------------------
// School coordinates providers
// ---------------------------------------------------------------------------

final schoolsRepositoryProvider = Provider<SchoolsRepository>(
  (ref) => SchoolsRepository(ref.watch(dioClientProvider)),
);

final schoolCoordinatesProvider = FutureProvider.family<
    List<SchoolCoordinates>, ({String? provinceCode, String? communeCode})>(
  (ref, filters) async {
    final repo = ref.watch(schoolsRepositoryProvider);
    return repo.getSchoolCoordinates(
      provinceCode: filters.provinceCode,
      communeCode: filters.communeCode,
    );
  },
);

final selectedSchoolProvider = StateProvider<SchoolCoordinates?>((ref) => null);

// Provider to track selected school UIDs to show on map
final selectedSchoolUidsProvider = StateProvider<List<String>>((ref) => []);

// ---------------------------------------------------------------------------
// Committee providers (2025 reform — People's Committee HQ / Trụ sở UBND)
// ---------------------------------------------------------------------------

final committeesProvider =
    FutureProvider<Result<List<CommitteeModel>>>((ref) async {
  final repo = ref.watch(geoRepositoryProvider);
  final result = await repo.getCommittees();
  return result;
});

final committeesByProvinceProvider =
    FutureProvider.family<Result<List<CommitteeModel>>, String>(
        (ref, provinceCode) async {
  final repo = ref.watch(geoRepositoryProvider);
  final result = await repo.getCommitteesByProvince(provinceCode);
  return result;
});

// ---------------------------------------------------------------------------
// Province boundary providers (from backend API)
// ---------------------------------------------------------------------------

/// Parses province boundary GeoJSON from the backend API into ProvincePolygonEntry structs.
/// Uses the bulk endpoint /provinces-boundaries so it's one request instead of 63.
final provincePolygonEntriesProvider =
    FutureProvider<List<ProvincePolygonEntry>>((ref) async {
  final repo = ref.watch(geoRepositoryProvider);
  final result = await repo.getAllProvincesBoundaries();

  return result.when(
    ok: (data) => _parseFeatureCollection(data),
    err: (_) => [],
  );
});

/// Parses a GeoJSON FeatureCollection from the backend into ProvincePolygonEntry list.
List<ProvincePolygonEntry> _parseFeatureCollection(
    Map<String, dynamic> collection) {
  final features = collection['features'] as List<dynamic>? ?? [];
  final entries = <ProvincePolygonEntry>[];

  for (final feature in features.cast<Map<String, dynamic>>()) {
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    if (geometry == null) continue;

    final code = feature['code'] as String? ?? '';
    final name = feature['name'] as String? ?? '';
    if (code.isEmpty) continue;

    final coords = geometry['coordinates'];
    if (coords == null) continue;

    final rings = extractRings(coords);
    if (rings.isEmpty) continue;

    final centroid = computeCentroid(rings.first);
    entries.add(ProvincePolygonEntry(
      code: code,
      name: name,
      rings: rings,
      centroid: centroid,
    ));
  }

  return entries;
}

/// Loads and renders individual commune boundaries for a given province.
/// Uses bulk endpoint for fast loading, filters out empty boundaries.
/// Returns a list of (commune code, commune name, polygons) for all communes.
final communeBoundariesProvider = FutureProvider.family<
    List<({String code, String name, List<Polygon> polygons})>,
    String>((ref, provinceCode) async {
  final repo = ref.watch(geoRepositoryProvider);
  
  // Use bulk endpoint for faster loading - single API call instead of N calls
  final boundariesResult = await repo.getCommunesBoundaries(provinceCode);

  return boundariesResult.when(
    ok: (features) {
      final entries = <({String code, String name, List<Polygon> polygons})>[];

      for (final feature in features) {
        // Skip features with empty or invalid coordinates
        if (feature.geometry.coordinates.isEmpty) continue;
        
        try {
          final polygons = GeoJsonUtils.parseGeoJsonToPolygons(
            feature.geometry.coordinates,
            fillColor: const Color(0x1500ACC1),
            borderColor: const Color(0xFF00796B),
            borderStrokeWidth: 1.5,
          );
          
          // Only add entries with valid polygons
          if (polygons.isNotEmpty) {
            entries.add((
              code: feature.code,
              name: feature.name,
              polygons: polygons,
            ));
          }
        } catch (_) {
          // Skip malformed boundary data
        }
      }

      return entries;
    },
    err: (_) => [],
  );
});

/// Loading state for commune boundaries - tracks when loading starts/ends
final communeBoundariesLoadingProvider =
    StateProvider.family<bool, String>((ref, provinceCode) => false);

/// Returns province centroid map (code -> LatLng) from the precomputed values in
/// ProvincePolygonEntry. No parsing needed on the main thread.
final provinceCentroidsProvider =
    FutureProvider<Map<String, LatLng>>((ref) async {
  final entries = await ref.watch(provincePolygonEntriesProvider.future);
  final centroids = <String, LatLng>{};
  for (final e in entries) {
    if (e.centroid != null) {
      centroids[e.code] = LatLng(e.centroid!['lat']!, e.centroid!['lng']!);
    }
  }
  return centroids;
});

/// Computes centroid coordinates for all communes of a given province
/// from the polygon data already loaded by communeBoundariesProvider.
/// Returns a map of commune code -> LatLng centroid.
final communeCentroidsProvider =
    FutureProvider.family<Map<String, LatLng>, String>(
        (ref, provinceCode) async {
  final entries =
      await ref.watch(communeBoundariesProvider(provinceCode).future);
  final centroids = <String, LatLng>{};

  for (final entry in entries) {
    for (final polygon in entry.polygons) {
      final centroid = GeoJsonUtils.computePolygonCentroid(polygon.points);
      if (centroid != null) {
        centroids[entry.code] = centroid;
        break;
      }
    }
  }

  return centroids;
});
