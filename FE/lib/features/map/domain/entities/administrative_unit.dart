import 'unit_level.dart';

class AdministrativeUnit {
  const AdministrativeUnit({
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
}
