import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Loads bundled GeoJSON assets (provinces.geojson) that were sourced from
/// https://huggingface.co/datasets/tmquan/sapnhap-bando-vn
///
/// The file is a standard GeoJSON FeatureCollection where each Feature has:
///   properties: { ma, ten, type, area_km2, ... }
///   geometry: { type: "MultiPolygon", coordinates: [...] }
class GeoLocalDataSource {
  static const _provincesAssetPath = 'assets/geo/provinces.geojson';

  Map<String, dynamic>? _cachedProvinces;

  /// Loads and caches the provinces GeoJSON FeatureCollection.
  Future<Map<String, dynamic>> loadProvincesGeoJson() async {
    if (_cachedProvinces != null) return _cachedProvinces!;

    try {
      final jsonString = await rootBundle.loadString(_provincesAssetPath);
      _cachedProvinces = json.decode(jsonString) as Map<String, dynamic>;
      return _cachedProvinces!;
    } catch (e) {
      debugPrint('Failed to load provinces GeoJSON from assets: $e');
      rethrow;
    }
  }

  /// Extracts all features from the FeatureCollection.
  Future<List<Map<String, dynamic>>> getProvinceFeatures() async {
    final geoJson = await loadProvincesGeoJson();
    final features = geoJson['features'] as List<dynamic>? ?? [];
    return features.cast<Map<String, dynamic>>();
  }
}
