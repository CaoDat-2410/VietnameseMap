import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads bundled GeoJSON assets (provinces.geojson) sourced from
/// https://huggingface.co/datasets/tmquan/sapnhap-bando-vn
///
/// Cache versioning: uses 'geo_cache_v2' key to distinguish from old v1 cache
/// during migration. Old cache keys are automatically cleared on first launch.
class GeoLocalDataSource {
  static const _provincesAssetPath = 'assets/geo/provinces.geojson';
  static const _cacheVersionKey = 'geo_cache_version';
  static const _currentCacheVersion = 'v2';

  List<ProvincePolygonEntry>? _cachedEntries;

  /// Returns cached ProvincePolygonEntry list. All parsing + centroid computation
  /// runs in a background isolate (via compute()) so the main thread is never blocked.
  Future<List<ProvincePolygonEntry>> getPolygonEntries() async {
    await _checkAndClearOldCache();
    if (_cachedEntries != null) return _cachedEntries!;

    try {
      final jsonString = await rootBundle.loadString(_provincesAssetPath);
      _cachedEntries = await compute(_parseAndBuildEntries, jsonString);
      return _cachedEntries!;
    } catch (e) {
      debugPrint('Failed to load provinces GeoJSON from assets: $e');
      rethrow;
    }
  }

  /// Clears old cache version if detected. Should be called on app startup.
  Future<void> _checkAndClearOldCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedVersion = prefs.getString(_cacheVersionKey);

      if (cachedVersion != _currentCacheVersion) {
        debugPrint(
            'Cache version mismatch. Old: $cachedVersion, Current: $_currentCacheVersion');
        debugPrint('Clearing old geo cache...');

        // Clear any old cache keys
        final keys = prefs.getKeys();
        for (final key in keys) {
          if (key.startsWith('geo_cache')) {
            await prefs.remove(key);
          }
        }

        // Mark new cache version
        await prefs.setString(_cacheVersionKey, _currentCacheVersion);
        debugPrint('Geo cache cleared and marked as $_currentCacheVersion');
      }
    } catch (e) {
      debugPrint('Failed to check/clear old cache: $e');
    }
  }

  /// Force clear cache (useful for testing or manual reset)
  Future<void> clearCache() async {
    _cachedEntries = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('geo_cache')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }
}

/// Lightweight entry — all fields are plain Dart (no Flutter/Map objects).
/// Centroid is precomputed in the isolate so the main thread never parses polygons.
class ProvincePolygonEntry {
  final String code;
  final String name;
  final List<List<Map<String, double>>> rings;
  final Map<String, double>? centroid;

  const ProvincePolygonEntry({
    required this.code,
    required this.name,
    required this.rings,
    this.centroid,
  });
}

/// Top-level function for compute(). Parses JSON + extracts rings + computes centroid.
List<ProvincePolygonEntry> _parseAndBuildEntries(String jsonString) {
  final decoded = json.decode(jsonString) as Map<String, dynamic>;
  final features = decoded['features'] as List<dynamic>? ?? [];

  final entries = <ProvincePolygonEntry>[];
  for (final feature in features.cast<Map<String, dynamic>>()) {
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final properties = feature['properties'] as Map<String, dynamic>?;
    if (geometry == null || properties == null) continue;

    final coords = geometry['coordinates'];
    if (coords == null) continue;

    final code = properties['ma'] as String? ?? '';
    final name = properties['ten'] as String? ?? '';
    if (code.isEmpty) continue;

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

/// Recursively extracts rings from GeoJSON MultiPolygon/Polygon coordinates.
List<List<Map<String, double>>> extractRings(dynamic coords) {
  final rings = <List<Map<String, double>>>[];

  bool isPosition(dynamic value) =>
      value is List &&
      value.length >= 2 &&
      value[0] is num &&
      value[1] is num;

  bool isRing(dynamic value) =>
      value is List && value.isNotEmpty && isPosition(value.first);

  void addRing(dynamic ringCoords) {
    if (ringCoords is! List || ringCoords.isEmpty) return;
    final ring = <Map<String, double>>[];
    for (final point in ringCoords) {
      if (isPosition(point)) {
        ring.add({
          'lat': (point[1] as num).toDouble(),
          'lng': (point[0] as num).toDouble()
        });
      }
    }
    if (ring.isNotEmpty) rings.add(ring);
  }

  void walk(dynamic value) {
    if (isRing(value)) {
      addRing(value);
      return;
    }
    if (value is List) {
      for (final child in value) {
        walk(child);
      }
    }
  }

  walk(coords);
  return rings;
}

/// Computes the centroid (average lat/lng) of a ring.
Map<String, double>? computeCentroid(List<Map<String, double>> ring) {
  if (ring.isEmpty) return null;
  double sumLat = 0, sumLng = 0;
  for (final p in ring) {
    sumLat += p['lat']!;
    sumLng += p['lng']!;
  }
  return {'lat': sumLat / ring.length, 'lng': sumLng / ring.length};
}
