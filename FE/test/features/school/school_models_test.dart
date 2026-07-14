import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/features/school/shared/models/school_model.dart';

void main() {
  group('SchoolModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'schoolUid': 'SCH001',
        'provinceCode': '01',
        'provinceName': 'Hà Nội',
        'communeCode': '001',
        'communeName': 'Phường Ba Đình',
        'schoolCode': 'SCH001',
        'schoolName': 'THPT Ba Đình',
        'address': '123 Điện Biên Phủ',
        'areaType': 'KV1',
      };
      final model = SchoolModel.fromJson(json);
      expect(model.schoolUid, 'SCH001');
      expect(model.provinceCode, '01');
      expect(model.provinceName, 'Hà Nội');
      expect(model.communeCode, '001');
      expect(model.communeName, 'Phường Ba Đình');
      expect(model.schoolCode, 'SCH001');
      expect(model.schoolName, 'THPT Ba Đình');
      expect(model.address, '123 Điện Biên Phủ');
      expect(model.areaType, 'KV1');
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final model = SchoolModel.fromJson(json);
      expect(model.schoolUid, '');
      expect(model.provinceCode, '');
      expect(model.provinceName, '');
      expect(model.communeCode, isNull);
      expect(model.communeName, isNull);
      expect(model.schoolCode, '');
      expect(model.schoolName, '');
      expect(model.address, '');
      expect(model.areaType, '');
    });
  });

  group('SchoolCoordinates', () {
    test('hasCoordinates returns true when lat/lng present', () {
      final model = SchoolCoordinates.fromJson({
        'schoolUid': 'SCH001',
        'schoolName': 'Test School',
        'latitude': 21.0285,
        'longitude': 105.8542,
        'geocodeStatus': 'EXACT',
      });
      expect(model.hasCoordinates, isTrue);
    });

    test('hasCoordinates returns false when lat/lng null', () {
      final model = SchoolCoordinates.fromJson({
        'schoolUid': 'SCH001',
        'schoolName': 'Test School',
      });
      expect(model.hasCoordinates, isFalse);
    });

    test('isExact returns true for EXACT status', () {
      final model = SchoolCoordinates.fromJson({
        'schoolUid': 'SCH001',
        'schoolName': 'Test School',
        'latitude': 21.0285,
        'longitude': 105.8542,
        'geocodeStatus': 'EXACT',
      });
      expect(model.isExact, isTrue);
      expect(model.isApproximate, isFalse);
    });

    test('isApproximate returns true for APPROXIMATE status', () {
      final model = SchoolCoordinates.fromJson({
        'schoolUid': 'SCH001',
        'schoolName': 'Test School',
        'latitude': 21.0285,
        'longitude': 105.8542,
        'geocodeStatus': 'APPROXIMATE',
      });
      expect(model.isApproximate, isTrue);
      expect(model.isExact, isFalse);
    });

    test('isFull returns true for FULL status', () {
      final model = SchoolCoordinates.fromJson({
        'schoolUid': 'SCH001',
        'schoolName': 'Test School',
        'latitude': 21.0285,
        'longitude': 105.8542,
        'geocodeStatus': 'FULL',
      });
      expect(model.isFull, isTrue);
    });

    test('handles null geocodeStatus', () {
      final model = SchoolCoordinates.fromJson({
        'schoolUid': 'SCH001',
        'schoolName': 'Test School',
        'latitude': 21.0285,
        'longitude': 105.8542,
      });
      expect(model.geocodeStatus, isNull);
      expect(model.isExact, isFalse);
      expect(model.isApproximate, isFalse);
      expect(model.isFull, isFalse);
    });
  });

  group('PagedResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'items': [
          {'schoolUid': 'SCH001', 'schoolName': 'School 1'},
          {'schoolUid': 'SCH002', 'schoolName': 'School 2'},
        ],
        'page': 0,
        'pageSize': 20,
        'totalItems': 100,
        'totalPages': 5,
      };
      final model = PagedResponse<SchoolModel>.fromJson(
        json,
        (item) => SchoolModel.fromJson(item as Map<String, dynamic>),
      );
      expect(model.items.length, 2);
      expect(model.page, 0);
      expect(model.pageSize, 20);
      expect(model.totalItems, 100);
      expect(model.totalPages, 5);
    });

    test('fromJson handles empty items', () {
      final json = {
        'items': [],
        'page': 0,
        'pageSize': 20,
        'totalItems': 0,
        'totalPages': 0,
      };
      final model = PagedResponse<SchoolModel>.fromJson(
        json,
        (item) => SchoolModel.fromJson(item as Map<String, dynamic>),
      );
      expect(model.items, isEmpty);
      expect(model.totalItems, 0);
    });
  });
}
