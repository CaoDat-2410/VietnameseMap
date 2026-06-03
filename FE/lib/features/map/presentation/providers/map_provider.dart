import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/geojson_utils.dart';
import '../../data/datasources/geo_remote_datasource.dart';
import '../../data/repositories/geo_repository_impl.dart';
import '../../domain/entities/administrative_unit_summary.dart';
import '../../domain/repositories/geo_repository.dart';
import '../../domain/usecases/get_districts.dart';
import '../../domain/usecases/get_provinces.dart';
import '../../domain/usecases/get_wards.dart';
import '../../domain/usecases/get_wards_boundaries_by_district_id.dart';
import '../../data/datasources/geo_local_datasource.dart'
    show ProvincePolygonEntry, extractRings, computeCentroid;

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

final getWardsProvider = Provider(
  (ref) => GetWards(ref.watch(geoRepositoryProvider)),
);

final getWardsBoundariesByDistrictIdProvider = Provider(
  (ref) => GetWardsBoundariesByDistrictId(ref.watch(geoRepositoryProvider)),
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

final wardsProvider =
    FutureProvider.family<Result<List<AdministrativeUnitSummary>>, String>(
        (ref, districtCode) {
  return ref.watch(getWardsProvider).call(districtCode);
});

final selectedProvinceProvider = StateProvider<AdministrativeUnitSummary?>((ref) => null);
final selectedDistrictProvider = StateProvider<({String code, String name, int id})?>((ref) => null);
final selectedWardProvider = StateProvider<({String code, int? id, String name})?>((ref) => null);

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
List<ProvincePolygonEntry> _parseFeatureCollection(Map<String, dynamic> collection) {
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

/// Loads and renders individual district boundaries for a given province.
/// Returns a list of (district code, district name, polygons) for all districts.
final districtBoundariesProvider = FutureProvider.family<
    List<({String code, String name, List<Polygon> polygons})>, String>(
  (ref, provinceCode) async {
    final repo = ref.watch(geoRepositoryProvider);
    final districtsResult = await repo.getDistricts(provinceCode);

    return districtsResult.when(
      ok: (districts) async {
        final entries = <({String code, String name, List<Polygon> polygons})>[];

        for (final district in districts) {
          final boundaryResult = await repo.getUnitBoundary(district.code);
          boundaryResult.when(
            ok: (feature) {
              try {
                final coords = feature.geometry.coordinates;
                if (coords.isNotEmpty) {
                  final polygons = GeoJsonUtils.parseGeoJsonToPolygons(
                    coords,
                    fillColor: const Color(0x1500ACC1),
                    borderColor: const Color(0xFF00796B),
                    borderStrokeWidth: 1.5,
                  );
                  if (polygons.isNotEmpty) {
                    entries.add((code: district.code, name: district.name, polygons: polygons));
                  }
                }
              } catch (_) {}
            },
            err: (_) {},
          );
        }

        return entries;
      },
      err: (_) => [],
    );
  },
);

/// Loads and renders individual ward boundaries for a given district.
/// Uses the bulk endpoint that fetches all ward boundaries at once using districtId
/// to avoid duplicate ward code issues.
final wardBoundariesProvider = FutureProvider.family<
    List<({String code, int? id, String name, List<Polygon> polygons})>, int>(
  (ref, districtId) async {
    final getWardsBoundaries = ref.watch(getWardsBoundariesByDistrictIdProvider);
    final result = await getWardsBoundaries.call(districtId);

    return result.when(
      ok: (features) {
        final entries = <({String code, int? id, String name, List<Polygon> polygons})>[];

        for (final feature in features) {
          try {
            final coords = feature.geometry.coordinates;
            if (coords.isNotEmpty) {
              final polygons = GeoJsonUtils.parseGeoJsonToPolygons(
                coords,
                fillColor: const Color(0x1A9C27B0),
                borderColor: const Color(0xFF9C27B0),
                borderStrokeWidth: 1.5,
              );
              if (polygons.isNotEmpty) {
                entries.add((code: feature.code, id: feature.id, name: feature.name, polygons: polygons));
              }
            }
          } catch (_) {}
        }

        return entries;
      },
      err: (_) => [],
    );
  },
);

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

/// Computes centroid coordinates for all districts of a given province
/// from the polygon data already loaded by districtBoundariesProvider.
/// Returns a map of district code -> LatLng centroid.
final districtCentroidsProvider =
    FutureProvider.family<Map<String, LatLng>, String>((ref, provinceCode) async {
  final entries = await ref.watch(districtBoundariesProvider(provinceCode).future);
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

/// Fetches centroid coordinates for all wards of a given district.
/// Returns a map of ward code -> LatLng centroid.
final wardCentroidsProvider =
    FutureProvider.family<Map<String, LatLng>, int>((ref, districtId) async {
  final wardsResult = await ref.watch(wardBoundariesProvider(districtId).future);
  final centroids = <String, LatLng>{};

  for (final entry in wardsResult) {
    for (final polygon in entry.polygons) {
      final centroid = GeoJsonUtils.computePolygonCentroid(polygon.points);
      if (centroid != null) {
        centroids[_wardEntryKey(entry.id, entry.code, entry.name)] = centroid;
        break;
      }
    }
  }

  return centroids;
});

String wardKey(int? id, String code, String name) =>
    id != null ? 'id:$id' : 'code:$code:$name';

String _wardEntryKey(int? id, String code, String name) =>
    wardKey(id, code, name);
