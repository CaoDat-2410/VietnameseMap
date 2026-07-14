import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Map optimization settings provider
class MapOptimizationProvider extends StateNotifier<MapOptimizationState> {
  MapOptimizationProvider() : super(MapOptimizationState.initial());

  /// Enable/disable progressive loading
  void setProgressiveLoading(bool enabled) {
    state = state.copyWith(progressiveLoading: enabled);
  }

  /// Enable/disable marker clustering
  void setMarkerClustering(bool enabled) {
    state = state.copyWith(markerClustering: enabled);
  }

  /// Set tile cache size (number of tiles to cache)
  void setTileCacheSize(int size) {
    state = state.copyWith(tileCacheSize: size);
  }

  /// Set simplified geometry flag
  void setSimplifiedGeometry(bool simplified) {
    state = state.copyWith(simplifiedGeometry: simplified);
  }

  /// Update current zoom level
  void setZoomLevel(double zoom) {
    if (state.currentZoom != zoom) {
      state = state.copyWith(currentZoom: zoom);
    }
  }
}

/// Map optimization state
class MapOptimizationState {
  final bool progressiveLoading;
  final bool markerClustering;
  final int tileCacheSize;
  final bool simplifiedGeometry;
  final double currentZoom;
  final Set<String> loadedBoundaryIds;

  MapOptimizationState({
    required this.progressiveLoading,
    required this.markerClustering,
    required this.tileCacheSize,
    required this.simplifiedGeometry,
    required this.currentZoom,
    required this.loadedBoundaryIds,
  });

  factory MapOptimizationState.initial() {
    return MapOptimizationState(
      progressiveLoading: true,
      markerClustering: true,
      tileCacheSize: 100,
      simplifiedGeometry: true,
      currentZoom: 6.0,
      loadedBoundaryIds: {},
    );
  }

  MapOptimizationState copyWith({
    bool? progressiveLoading,
    bool? markerClustering,
    int? tileCacheSize,
    bool? simplifiedGeometry,
    double? currentZoom,
    Set<String>? loadedBoundaryIds,
  }) {
    return MapOptimizationState(
      progressiveLoading: progressiveLoading ?? this.progressiveLoading,
      markerClustering: markerClustering ?? this.markerClustering,
      tileCacheSize: tileCacheSize ?? this.tileCacheSize,
      simplifiedGeometry: simplifiedGeometry ?? this.simplifiedGeometry,
      currentZoom: currentZoom ?? this.currentZoom,
      loadedBoundaryIds: loadedBoundaryIds ?? this.loadedBoundaryIds,
    );
  }
}

/// Provider for map optimization settings
final mapOptimizationProvider =
    StateNotifierProvider<MapOptimizationProvider, MapOptimizationState>((ref) {
  return MapOptimizationProvider();
});

/// Tile cache provider
class TileCache {
  final int maxSize;
  final Map<String, Uint8List> _cache = {};
  int _currentSize = 0;

  TileCache({this.maxSize = 100});

  void put(String key, Uint8List data) {
    if (_currentSize >= maxSize) {
      // Remove oldest entry
      final oldestKey = _cache.keys.first;
      _currentSize -= _cache[oldestKey]!.length;
      _cache.remove(oldestKey);
    }
    _cache[key] = data;
    _currentSize += data.length;
  }

  Uint8List? get(String key) {
    return _cache[key];
  }

  bool contains(String key) {
    return _cache.containsKey(key);
  }

  void clear() {
    _cache.clear();
    _currentSize = 0;
  }

  int get size => _cache.length;
}

/// Global tile cache instance
final tileCache = TileCache(maxSize: 100);

/// Boundary loader for progressive loading
class BoundaryLoader {
  static const double _provinceZoomThreshold = 8.0;
  static const double _districtZoomThreshold = 10.0;
  static const double _communeZoomThreshold = 12.0;

  /// Determine what boundaries to load at given zoom level
  static Set<String> getBoundariesToLoad(double zoom, Set<String> loaded) {
    if (zoom < _provinceZoomThreshold) {
      // Only load province boundaries
      return {'provinces'};
    } else if (zoom < _districtZoomThreshold) {
      // Load provinces + districts for visible provinces
      return {'provinces', 'districts'};
    } else if (zoom < _communeZoomThreshold) {
      // Load all levels
      return {'provinces', 'districts', 'communes'};
    } else {
      // Full detail
      return {'provinces', 'districts', 'communes', 'schools'};
    }
  }

  /// Simplify GeoJSON geometry for web performance
  static String simplifyGeoJSON(String geojson, double tolerance) {
    try {
      final decoded = jsonDecode(geojson);
      if (decoded is Map) {
        _simplifyFeatureCollection(decoded, tolerance);
      }
      return jsonEncode(decoded);
    } catch (e) {
      return geojson;
    }
  }

  static void _simplifyFeatureCollection(Map collection, double tolerance) {
    final features = collection['features'] as List?;
    if (features == null) return;

    for (final feature in features) {
      final geometry = feature['geometry'];
      if (geometry == null) continue;

      final coordinates = geometry['coordinates'];
      if (coordinates == null) continue;

      _simplifyCoordinates(coordinates, tolerance);
    }
  }

  static void _simplifyCoordinates(dynamic coords, double tolerance) {
    if (coords is List && coords.length > 2) {
      // Remove points that are too close together
      final simplified = <dynamic>[];
      for (int i = 0; i < coords.length; i++) {
        if (simplified.isEmpty) {
          simplified.add(coords[i]);
        } else {
          final last = simplified.last;
          if (last is List && coords[i] is List) {
            final distance = _calculateDistance(
              last[1] as num,
              last[0] as num,
              (coords[i] as List)[1] as num,
              (coords[i] as List)[0] as num,
            );
            if (distance > tolerance) {
              simplified.add(coords[i]);
            }
          }
        }
      }
      coords.clear();
      coords.addAll(simplified);
    }
  }

  static double _calculateDistance(
    num lat1,
    num lon1,
    num lat2,
    num lon2,
  ) {
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    return (dLat * dLat + dLon * dLon).toDouble();
  }
}
