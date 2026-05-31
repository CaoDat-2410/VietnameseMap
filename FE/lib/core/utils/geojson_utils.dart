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

    int depth = _getListDepth(coordinates);
    
    if (depth == 3) {
      // Polygon
      polygons.add(_createPolygon(coordinates, fillColor, borderColor, borderStrokeWidth));
    } else if (depth == 4) {
      // MultiPolygon
      for (final polyCoords in coordinates) {
        polygons.add(_createPolygon(polyCoords as List<dynamic>, fillColor, borderColor, borderStrokeWidth));
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
        holePoints.add(LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()));
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
}
