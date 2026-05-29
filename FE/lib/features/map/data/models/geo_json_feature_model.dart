import '../../domain/entities/geo_json_feature.dart';
import '../../domain/entities/unit_level.dart';

class GeoJsonFeatureModel {
  const GeoJsonFeatureModel({
    required this.type,
    required this.code,
    required this.name,
    required this.level,
    this.parentCode,
    required this.geometry,
  });

  final String type;
  final String code;
  final String name;
  final UnitLevel level;
  final String? parentCode;
  final GeoJsonGeometryModel geometry;

  factory GeoJsonFeatureModel.fromJson(Map<String, dynamic> json) {
    return GeoJsonFeatureModel(
      type: json['type'] as String? ?? 'Feature',
      code: json['code'] as String,
      name: json['name'] as String,
      level: _parseLevel(json['level'] as String),
      parentCode: json['parentCode'] as String?,
      geometry: GeoJsonGeometryModel.fromJson(
          json['geometry'] as Map<String, dynamic>),
    );
  }

  GeoJsonFeature toEntity() => GeoJsonFeature(
        type: type,
        code: code,
        name: name,
        level: level,
        parentCode: parentCode,
        geometry: geometry.toEntity(),
      );

  static UnitLevel _parseLevel(String raw) => switch (raw.toUpperCase()) {
        'PROVINCE' => UnitLevel.province,
        'DISTRICT' => UnitLevel.district,
        _ => UnitLevel.ward,
      };
}

class GeoJsonGeometryModel {
  const GeoJsonGeometryModel({
    required this.type,
    required this.coordinates,
  });

  final String type;
  final dynamic coordinates;

  factory GeoJsonGeometryModel.fromJson(Map<String, dynamic> json) {
    return GeoJsonGeometryModel(
      type: json['type'] as String,
      coordinates: json['coordinates'],
    );
  }

  GeoJsonGeometry toEntity() =>
      GeoJsonGeometry(type: type, coordinates: coordinates);
}
