import 'unit_level.dart';

class AdministrativeUnitSummary {
  const AdministrativeUnitSummary({
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
}
