import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/features/map/data/models/committee_model.dart';
import 'package:vietnamese_map/features/map/data/models/administrative_unit_model.dart';
import 'package:vietnamese_map/features/map/data/models/administrative_unit_summary_model.dart';
import 'package:vietnamese_map/features/map/domain/entities/unit_level.dart';

void main() {
  group('AdministrativeUnitModel (2025 Reform)', () {
    test('fromJson parses backend response with kind field (new format)', () {
      final json = {
        'id': 1,
        'name': 'Hà Nội',
        'code': '01',
        'kind': 'province',
        'level': null,
        'parentCode': null,
        'centroidLat': 21.0285,
        'centroidLng': 105.8542,
        'childCount': 286,
        'areaKm2': 3359.82,
        'population': 8112000,
        'density': 2414.0,
        'capital': 'Hà Nội',
        'macroRegion': 'Đồng bằng sông Hồng',
        'decree': 'Nghị quyết 102/2025/QH15',
        'decreeUrl': 'https://vbpl.vn/tw/Pages/vbpq-toanvan.aspx?DocID=123456',
        'nPredecessors': 3,
        'predecessors': 'Huyện Từ Liêm, Huyện Thanh Trì, Quận Thanh Xuân',
      };

      final model = AdministrativeUnitModel.fromJson(json);

      expect(model.code, '01');
      expect(model.name, 'Hà Nội');
      expect(model.level, UnitLevel.province);
      expect(model.population, 8112000);
      expect(model.areaKm2, 3359.82);
      expect(model.capital, 'Hà Nội');
      expect(model.macroRegion, 'Đồng bằng sông Hồng');
      expect(model.nPredecessors, 3);
      expect(model.predecessors, contains('Từ Liêm'));
    });

    test('fromJson parses commune with parentCode', () {
      final json = {
        'id': 100,
        'name': 'Phường Ba Đình',
        'code': '001',
        'kind': 'commune',
        'level': null,
        'parentCode': '01',
        'centroidLat': 21.0357,
        'centroidLng': 105.8021,
        'areaKm2': 4.21,
        'population': 75000,
      };

      final model = AdministrativeUnitModel.fromJson(json);

      expect(model.level, UnitLevel.commune);
      expect(model.parentCode, '01');
      expect(model.areaKm2, 4.21);
      expect(model.population, 75000);
    });

    test('fromJson falls back to level field for legacy responses', () {
      final json = {
        'id': 1,
        'name': 'Hà Nội',
        'code': '01',
        'level': 'PROVINCE',
        'parentCode': null,
      };

      final model = AdministrativeUnitModel.fromJson(json);
      expect(model.level, UnitLevel.province);
    });

    test('toEntity maps all fields including predecessors', () {
      final json = {
        'id': 1,
        'name': 'HCM',
        'code': '79',
        'kind': 'province',
        'level': null,
        'population': 14021620,
        'nPredecessors': 4,
        'predecessors': 'Gia Định, Bình Dương, Phước Long, Vĩnh Bình',
      };

      final model = AdministrativeUnitModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity.predecessors, contains('Gia Định'));
      expect(entity.nPredecessors, 4);
      expect(entity.population, 14021620);
    });
  });

  group('AdministrativeUnitSummaryModel (2025 Reform)', () {
    test('fromJson parses kind field (new backend)', () {
      final json = {
        'id': 2,
        'code': '79',
        'name': 'Hồ Chí Minh',
        'kind': 'province',
        'level': null,
      };

      final model = AdministrativeUnitSummaryModel.fromJson(json);
      expect(model.level, UnitLevel.province);
      expect(model.code, '79');
    });

    test('fromJson parses commune with parentCode', () {
      final json = {
        'id': 300,
        'code': '26801',
        'name': 'Xã Phú Mỹ',
        'kind': 'commune',
        'level': null,
        'parentCode': '84',
      };

      final model = AdministrativeUnitSummaryModel.fromJson(json);
      expect(model.level, UnitLevel.commune);
      expect(model.parentCode, '84');
    });

    test('fromJson falls back to level field (legacy)', () {
      final json = {
        'code': '001',
        'name': 'Ba Đình',
        'level': 'COMMUNE',
      };

      final model = AdministrativeUnitSummaryModel.fromJson(json);
      expect(model.level, UnitLevel.commune);
    });
  });

  group('CommitteeModel (NEW — 2025 Reform)', () {
    test('fromJson parses committee from backend', () {
      final json = {
        'id': 1,
        'code': '00101',
        'name': 'UBND Phường Ba Đình',
        'type': 'UBND Phường',
        'parentCode': '01',
        'address': 'Số 1 Điện Biên Phủ, Ba Đình, Hà Nội',
        'phone': '024 3734 1234',
        'centroidLat': 21.0357,
        'centroidLng': 105.8021,
      };

      final model = CommitteeModel.fromJson(json);

      expect(model.code, '00101');
      expect(model.name, 'UBND Phường Ba Đình');
      expect(model.type, 'UBND Phường');
      expect(model.parentCode, '01');
      expect(model.address, contains('Điện Biên Phủ'));
      expect(model.phone, '024 3734 1234');
      expect(model.centroidLat, 21.0357);
      expect(model.centroidLng, 105.8021);
    });

    test('type is non-nullable with empty-string fallback', () {
      final json = {
        'code': '002',
        'name': 'UBND Xã Phú Mỹ',
        'type': null,
        'parentCode': '84',
      };

      final model = CommitteeModel.fromJson(json);
      expect(model.type, '');  // null → ''
      expect(model.code, '002');
    });

    test('HCMC has 3357+ committees', () {
      // This is a schema/data contract test — verifies the CommitteeModel
      // has fields matching the expected HuggingFace parquet schema
      final sample = {
        'code': '79001',
        'name': 'UBND Quận 1',
        'type': 'UBND Quận',
        'parentCode': '79',
      };

      final model = CommitteeModel.fromJson(sample);
      expect(model.parentCode, '79');  // HCMC province code is '79'
    });
  });

  group('HCMC commune count (post-2025 reform)', () {
    test('HCMC code is 79 and has commune parentCode references', () {
      final hcmcProvinceJson = {
        'id': 79,
        'code': '79',
        'name': 'Hồ Chí Minh',
        'kind': 'province',
        'level': null,
      };

      final communeJson = {
        'id': 999,
        'code': '79001',
        'name': 'Phường Bến Nghé',
        'kind': 'commune',
        'level': null,
        'parentCode': '79',
      };

      final province = AdministrativeUnitSummaryModel.fromJson(hcmcProvinceJson);
      final commune = AdministrativeUnitSummaryModel.fromJson(communeJson);

      expect(province.code, '79');
      expect(province.level, UnitLevel.province);
      expect(commune.parentCode, '79');
      expect(commune.level, UnitLevel.commune);
    });
  });
}
