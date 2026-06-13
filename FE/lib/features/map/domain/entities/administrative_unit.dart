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
    // New fields from HuggingFace dataset
    this.areaKm2,
    this.population,
    this.density,
    this.capital,
    this.address,
    this.phone,
    this.decree,
    this.decreeUrl,
    this.macroRegion,
    this.nPredecessors,
    this.predecessors,
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

  // New fields from HuggingFace dataset
  final double? areaKm2;
  final int? population;
  final double? density;
  final String? capital;
  final String? address;
  final String? phone;
  final String? decree;
  final String? decreeUrl;
  final String? macroRegion;
  final int? nPredecessors;
  final String? predecessors;
}
