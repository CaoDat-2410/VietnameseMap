import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Loads bundled GeoJSON assets (provinces.geojson) sourced from
/// https://huggingface.co/datasets/tmquan/sapnhap-bando-vn
class GeoLocalDataSource {
  static const _provincesAssetPath = 'assets/geo/provinces.geojson';

  List<ProvincePolygonEntry>? _cachedEntries;

  /// Returns cached ProvincePolygonEntry list. All parsing + centroid computation
  /// runs in a background isolate (via compute()) so the main thread is never blocked.
  Future<List<ProvincePolygonEntry>> getPolygonEntries() async {
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

  void extractRing(dynamic ringCoords) {
    if (ringCoords is! List || ringCoords.isEmpty) return;
    final ring = <Map<String, double>>[];
    for (final point in ringCoords) {
      if (point is List && point.length >= 2 && point[0] is num && point[1] is num) {
        ring.add({'lat': (point[1] as num).toDouble(), 'lng': (point[0] as num).toDouble()});
      }
    }
    if (ring.isNotEmpty) rings.add(ring);
  }

  if (coords is List && coords.isNotEmpty) {
    final first = coords.first;
    if (first is List && first.isNotEmpty) {
      final second = first.first;
      if (second is List) {
        for (final polygon in coords) {
          extractRing(polygon);
        }
      } else {
        extractRing(coords);
      }
    }
  }

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
