import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GeoJsonUtils {
  static List<Polygon> parseGeoJsonToPolygons(
    dynamic coordinates, {
    Color fillColor = const Color(0x332196F3),
    Color borderColor = Colors.blue,
    double borderStrokeWidth = 2.0,
  }) {
    final polygons = <Polygon>[];

    if (coordinates is! List) return polygons;

    final int depth = _getListDepth(coordinates);

    if (depth == 3) {
      // Polygon
      polygons.add(_createPolygon(
          coordinates, fillColor, borderColor, borderStrokeWidth));
    } else if (depth == 4) {
      // MultiPolygon
      for (final polyCoords in coordinates) {
        polygons.add(_createPolygon(polyCoords as List<dynamic>, fillColor,
            borderColor, borderStrokeWidth));
      }
    }

    return polygons;
  }

  static Polygon _createPolygon(
    List<dynamic> rings,
    Color fillColor,
    Color borderColor,
    double borderStrokeWidth,
  ) {
    if (rings.isEmpty) return Polygon(points: const []);

    final exteriorRing = rings.first as List<dynamic>;
    final points = <LatLng>[];
    for (final point in exteriorRing) {
      final p = point as List<dynamic>;
      points.add(LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()));
    }

    final holePointsList = <List<LatLng>>[];
    for (int i = 1; i < rings.length; i++) {
      final holeRing = rings[i] as List<dynamic>;
      final holePoints = <LatLng>[];
      for (final point in holeRing) {
        final p = point as List<dynamic>;
        holePoints
            .add(LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()));
      }
      holePointsList.add(holePoints);
    }

    return Polygon(
      points: points,
      holePointsList: holePointsList.isNotEmpty ? holePointsList : null,
      color: fillColor,
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
    );
  }

  static int _getListDepth(dynamic list) {
    if (list is List && list.isNotEmpty) {
      return 1 + _getListDepth(list.first);
    }
    return 0;
  }

  static LatLngBounds? getBoundsFromPolygons(List<Polygon> polygons) {
    if (polygons.isEmpty) return null;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    bool hasPoints = false;

    for (final polygon in polygons) {
      for (final point in polygon.points) {
        hasPoints = true;
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
    }

    if (!hasPoints) return null;

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  static LatLng? computePolygonCentroid(List<LatLng> points) {
    if (points.isEmpty) return null;
    double sumLat = 0;
    double sumLng = 0;
    for (final p in points) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }
    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  static bool pointInPolygon(LatLng point, List<LatLng> ring) {
    if (ring.isEmpty) return false;
    int intersections = 0;
    final n = ring.length;
    for (int i = 0; i < n; i++) {
      final a = ring[i];
      final b = ring[(i + 1) % n];
      if (((a.latitude > point.latitude) != (b.latitude > point.latitude)) &&
          (point.longitude <
              (b.longitude - a.longitude) *
                      (point.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude)) {
        intersections++;
      }
    }
    return intersections % 2 == 1;
  }

  static LatLngBounds? computeVietnamBounds(
      List<Map<String, dynamic>> provinceFeatures) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    bool hasPoints = false;

    for (final feature in provinceFeatures) {
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;
      final coords = geometry['coordinates'];
      if (coords == null) continue;

      void extractPoints(dynamic c) {
        if (c is List && c.isNotEmpty) {
          if (c.length == 2 && c[0] is num && c[1] is num) {
            final lng = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            if (lat < minLat) minLat = lat;
            if (lat > maxLat) maxLat = lat;
            if (lng < minLng) minLng = lng;
            if (lng > maxLng) maxLng = lng;
            hasPoints = true;
          } else {
            for (final item in c) {
              extractPoints(item);
            }
          }
        }
      }

      extractPoints(coords);
    }

    if (!hasPoints) return null;

    const buffer = 0.15;
    return LatLngBounds(
      LatLng(minLat - buffer, minLng - buffer),
      LatLng(maxLat + buffer, maxLng + buffer),
    );
  }

  static List<LatLng> extractVietnamOuterRing(
      List<Map<String, dynamic>> provinceFeatures) {
    final allPoints = <LatLng>[];
    for (final feature in provinceFeatures) {
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;
      final coords = geometry['coordinates'];
      if (coords == null) continue;

      void extractRingPoints(dynamic c) {
        if (c is List && c.isNotEmpty) {
          if (c.length == 2 && c[0] is num && c[1] is num) {
            allPoints.add(LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ));
          } else {
            for (final item in c) {
              extractRingPoints(item);
            }
          }
        }
      }

      extractRingPoints(coords);
    }
    return allPoints;
  }
}
