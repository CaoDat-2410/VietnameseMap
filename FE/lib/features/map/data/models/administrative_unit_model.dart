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

  factory AdministrativeUnitModel.fromJson(Map<String, dynamic> json) {
    return AdministrativeUnitModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      level: _parseLevel(json['level'] as String? ?? json['kind'] as String? ?? ''),
      parentId: json['parentId'] as int?,
      parentCode: json['parentCode'] as String?,
      centroidLat: (json['centroidLat'] as num?)?.toDouble(),
      centroidLng: (json['centroidLng'] as num?)?.toDouble(),
      childCount: json['childCount'] as int?,
      areaKm2: (json['areaKm2'] as num?)?.toDouble(),
      population: json['population'] as int?,
      density: (json['density'] as num?)?.toDouble(),
      capital: json['capital'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      decree: json['decree'] as String?,
      decreeUrl: json['decreeUrl'] as String?,
      macroRegion: json['macroRegion'] as String?,
      nPredecessors: json['nPredecessors'] as int?,
      predecessors: json['predecessors'] as String?,
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
        areaKm2: areaKm2,
        population: population,
        density: density,
        capital: capital,
        address: address,
        phone: phone,
        decree: decree,
        decreeUrl: decreeUrl,
        macroRegion: macroRegion,
        nPredecessors: nPredecessors,
        predecessors: predecessors,
      );

  static UnitLevel _parseLevel(String raw) => switch (raw.toUpperCase()) {
        'PROVINCE' => UnitLevel.province,
        'COMMUNE' => UnitLevel.commune,
        // Legacy support for old WARD level (maps to COMMUNE)
        'WARD' => UnitLevel.commune,
        _ => UnitLevel.commune,
      };
}
