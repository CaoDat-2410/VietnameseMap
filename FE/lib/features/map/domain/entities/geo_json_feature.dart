import 'unit_level.dart';

class GeoJsonFeature {
  const GeoJsonFeature({
    this.id,
    required this.type,
    required this.code,
    required this.name,
    required this.level,
    this.parentCode,
    required this.geometry,
  });

  final int? id;
  final String type;
  final String code;
  final String name;
  final UnitLevel level;
  final String? parentCode;
  final GeoJsonGeometry geometry;
}

class GeoJsonGeometry {
  const GeoJsonGeometry({
    required this.type,
    required this.coordinates,
  });

  final String type;
  final dynamic coordinates;
}
