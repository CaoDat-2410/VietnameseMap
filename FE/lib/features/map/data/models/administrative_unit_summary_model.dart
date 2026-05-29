import '../../domain/entities/administrative_unit_summary.dart';
import '../../domain/entities/unit_level.dart';

class AdministrativeUnitSummaryModel {
  const AdministrativeUnitSummaryModel({
    required this.code,
    required this.name,
    required this.level,
    this.parentId,
    this.parentCode,
  });

  final String code;
  final String name;
  final UnitLevel level;
  final int? parentId;
  final String? parentCode;

  factory AdministrativeUnitSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdministrativeUnitSummaryModel(
      code: json['code'] as String,
      name: json['name'] as String,
      level: _parseLevel(json['level'] as String),
      parentId: json['parentId'] as int?,
      parentCode: json['parentCode'] as String?,
    );
  }

  AdministrativeUnitSummary toEntity() => AdministrativeUnitSummary(
        code: code,
        name: name,
        level: level,
        parentId: parentId,
        parentCode: parentCode,
      );

  static UnitLevel _parseLevel(String raw) => switch (raw.toUpperCase()) {
        'PROVINCE' => UnitLevel.province,
        'DISTRICT' => UnitLevel.district,
        _ => UnitLevel.ward,
      };
}
