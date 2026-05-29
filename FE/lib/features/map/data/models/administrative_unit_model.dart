import '../../domain/entities/administrative_unit.dart';
import '../../domain/entities/unit_level.dart';

class AdministrativeUnitModel {
  const AdministrativeUnitModel({
    required this.id,
    required this.name,
    required this.code,
    required this.level,
    this.parentId,
    this.parentCode,
    this.centroidLat,
    this.centroidLng,
    this.childCount,
  });

  final int id;
  final String name;
  final String code;
  final UnitLevel level;
  final int? parentId;
  final String? parentCode;
  final double? centroidLat;
  final double? centroidLng;
  final int? childCount;

  factory AdministrativeUnitModel.fromJson(Map<String, dynamic> json) {
    return AdministrativeUnitModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      level: _parseLevel(json['level'] as String),
      parentId: json['parentId'] as int?,
      parentCode: json['parentCode'] as String?,
      centroidLat: (json['centroidLat'] as num?)?.toDouble(),
      centroidLng: (json['centroidLng'] as num?)?.toDouble(),
      childCount: json['childCount'] as int?,
    );
  }

  AdministrativeUnit toEntity() => AdministrativeUnit(
        id: id,
        name: name,
        code: code,
        level: level,
        parentId: parentId,
        parentCode: parentCode,
        centroidLat: centroidLat,
        centroidLng: centroidLng,
        childCount: childCount,
      );

  static UnitLevel _parseLevel(String raw) => switch (raw.toUpperCase()) {
        'PROVINCE' => UnitLevel.province,
        'DISTRICT' => UnitLevel.district,
        _ => UnitLevel.ward,
      };
}
