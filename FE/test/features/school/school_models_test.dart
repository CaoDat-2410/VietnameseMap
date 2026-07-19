import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/features/school/shared/models/school_model.dart';

void main() {
  group('SchoolModel', () {
    test('fromJson parses correctly', () {
      final model = SchoolModel.fromJson({
        'schoolUid': 'SCH001',
        'provinceCode': '01',
        'provinceName': 'Ha Noi',
        'communeCode': '001',
        'communeName': 'Ba Dinh',
        'schoolCode': 'SCH001',
        'schoolName': 'THPT Ba Dinh',
        'address': '123 Dien Bien Phu',
        'areaType': 'KV1',
      });
      expect(model.schoolUid, 'SCH001');
      expect(model.provinceCode, '01');
      expect(model.communeCode, '001');
      expect(model.schoolName, 'THPT Ba Dinh');
      expect(model.areaType, 'KV1');
    });

    test('fromJson supplies safe defaults for absent fields', () {
      final model = SchoolModel.fromJson({});
      expect(model.schoolUid, '');
      expect(model.communeCode, '');
      expect(model.schoolName, '');
      expect(model.hasCoordinates, isFalse);
    });
  });

  group('SchoolModel coordinates', () {
    Map<String, dynamic> coordinateJson({
      double? latitude,
      double? longitude,
      String? geocodeStatus,
    }) => {
      'schoolUid': 'SCH001',
      'schoolName': 'Test School',
      'latitude': latitude,
      'longitude': longitude,
      'geocodeStatus': geocodeStatus,
    };

    test('detects complete coordinate pairs', () {
      expect(
        SchoolModel.fromJson(coordinateJson(latitude: 21.0285, longitude: 105.8542)).hasCoordinates,
        isTrue,
      );
      expect(SchoolModel.fromJson(coordinateJson()).hasCoordinates, isFalse);
    });

    test('detects approximate geocoding only for APPROXIMATE status', () {
      expect(
        SchoolModel.fromJson(coordinateJson(geocodeStatus: 'APPROXIMATE')).isApproximate,
        isTrue,
      );
      expect(SchoolModel.fromJson(coordinateJson()).isApproximate, isFalse);
    });
  });

  group('PagedResponse', () {
    test('fromJson parses paginated school payload', () {
      final model = PagedResponse<SchoolModel>.fromJson({
        'items': [
          {'schoolUid': 'SCH001', 'schoolName': 'School 1'},
          {'schoolUid': 'SCH002', 'schoolName': 'School 2'},
        ],
        'page': 0,
        'limit': 20,
        'totalItems': 100,
        'totalPages': 5,
      }, (item) => SchoolModel.fromJson(item as Map<String, dynamic>));

      expect(model.items, hasLength(2));
      expect(model.page, 0);
      expect(model.limit, 20);
      expect(model.totalItems, 100);
      expect(model.totalPages, 5);
    });

    test('fromJson handles empty items', () {
      final model = PagedResponse<SchoolModel>.fromJson({
        'items': [],
      }, (item) => SchoolModel.fromJson(item as Map<String, dynamic>));
      expect(model.items, isEmpty);
      expect(model.limit, 50);
    });
  });
}