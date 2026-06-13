import '../../domain/entities/administrative_unit_summary.dart';
import '../../domain/entities/unit_level.dart';

class AdministrativeUnitSummaryModel {
  const AdministrativeUnitSummaryModel({
    this.id,
    required this.code,
    required this.name,
    required this.level,
    this.parentId,
    this.parentCode,
  });

  final int? id;
  final String code;
  final String name;
  final UnitLevel level;
  final int? parentId;
  final String? parentCode;

  factory AdministrativeUnitSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdministrativeUnitSummaryModel(
      id: json['id'] as int?,
      code: json['code'] as String,
      name: json['name'] as String,
      level: _parseLevel(json['level'] as String? ?? json['kind'] as String? ?? ''),
      parentId: json['parentId'] as int?,
      parentCode: json['parentCode'] as String?,
    );
  }

  AdministrativeUnitSummary toEntity() => AdministrativeUnitSummary(
        id: id,
        code: code,
        name: name,
        level: level,
        parentId: parentId,
        parentCode: parentCode,
      );

  static UnitLevel _parseLevel(String raw) => switch (raw.toUpperCase()) {
        'PROVINCE' => UnitLevel.province,
        'COMMUNE' => UnitLevel.commune,
        // Legacy support for old WARD level (maps to COMMUNE)
        'WARD' => UnitLevel.commune,
        'DISTRICT' => UnitLevel.commune,
        _ => UnitLevel.commune,
      };
}
