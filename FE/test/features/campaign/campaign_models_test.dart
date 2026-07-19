import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/features/campaign/shared/models/campaign_models.dart';

void main() {
  group('CampaignModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Test Campaign',
        'status': 'ACTIVE',
        'objective': 'Test objective',
        'startDate': '2026-01-01',
        'endDate': '2026-12-31',
        'ownerEmployeeId': 5,
      };
      final model = CampaignModel.fromJson(json);
      expect(model.id, 1);
      expect(model.name, 'Test Campaign');
      expect(model.status, 'ACTIVE');
      expect(model.objective, 'Test objective');
      expect(model.startDate, '2026-01-01');
      expect(model.endDate, '2026-12-31');
      expect(model.ownerEmployeeId, 5);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final model = CampaignModel.fromJson(json);
      expect(model.id, 0);
      expect(model.name, '');
      expect(model.status, '');
      expect(model.objective, '');
      expect(model.startDate, '');
      expect(model.endDate, '');
      expect(model.ownerEmployeeId, 0);
    });

    test('toRequest creates correct map', () {
      final model = CampaignModel(
        id: 1,
        name: 'Campaign',
        status: 'DRAFT',
        objective: 'Objective',
        startDate: '2026-01-01',
        endDate: '2026-12-31',
        ownerEmployeeId: 2,
      );
      final request = model.toRequest();
      expect(request['name'], 'Campaign');
      expect(request['status'], 'DRAFT');
      expect(request['objective'], 'Objective');
      expect(request['startDate'], '2026-01-01');
      expect(request['endDate'], '2026-12-31');
      expect(request['ownerEmployeeId'], 2);
    });
  });

  group('CampaignEventModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'campaignId': 5,
        'name': 'Event Name',
        'eventType': 'WORKSHOP',
        'status': 'UPCOMING',
        'startsAt': '2026-06-01T10:00:00',
        'endsAt': '2026-06-01T12:00:00',
        'note': 'Test note',
        'locationLabel': 'Hà Nội',
        'latitude': 21.0285,
        'longitude': 105.8542,
        'schoolUid': 'SCH001',
        'provinceCode': '01',
      };
      final model = CampaignEventModel.fromJson(json);
      expect(model.id, 1);
      expect(model.campaignId, 5);
      expect(model.name, 'Event Name');
      expect(model.eventType, 'WORKSHOP');
      expect(model.status, 'UPCOMING');
      expect(model.latitude, 21.0285);
      expect(model.longitude, 105.8542);
      expect(model.hasLocation, isTrue);
    });

    test('hasLocation returns false when coordinates are null', () {
      final model = CampaignEventModel.fromJson({
        'id': 1,
        'campaignId': 1,
        'name': 'Event',
        'eventType': 'WORKSHOP',
        'status': 'UPCOMING',
        'startsAt': '2026-06-01',
        'endsAt': '2026-06-01',
        'note': '',
      });
      expect(model.hasLocation, isFalse);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 1,
        'campaignId': 1,
        'name': 'Event',
        'eventType': 'WORKSHOP',
        'status': 'UPCOMING',
        'startsAt': '2026-06-01',
        'endsAt': '2026-06-01',
        'note': '',
      };
      final model = CampaignEventModel.fromJson(json);
      expect(model.locationLabel, '');
      expect(model.schoolUid, '');
      expect(model.provinceCode, '');
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
    });
  });

  group('EmployeeModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'fullName': 'Nguyễn Văn A',
        'role': 'STAFF',
      };
      final model = EmployeeModel.fromJson(json);
      expect(model.id, 1);
      expect(model.fullName, 'Nguyễn Văn A');
      expect(model.role, 'STAFF');
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final model = EmployeeModel.fromJson(json);
      expect(model.id, 0);
      expect(model.fullName, '');
      expect(model.role, '');
    });
  });

  group('InteractionModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'eventId': 5,
        'schoolUid': 'SCH001',
        'participantType': 'STUDENT',
        'participantId': 100,
        'channel': 'PHONE',
        'outcome': 'SUCCESSFUL',
        'note': 'Called successfully',
        'createdAt': '2026-06-01T10:00:00',
      };
      final model = InteractionModel.fromJson(json);
      expect(model.id, 1);
      expect(model.eventId, 5);
      expect(model.schoolUid, 'SCH001');
      expect(model.participantType, 'STUDENT');
      expect(model.outcome, 'SUCCESSFUL');
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final model = InteractionModel.fromJson(json);
      expect(model.id, 0);
      expect(model.eventId, 0);
      expect(model.schoolUid, '');
      expect(model.participantType, '');
      expect(model.channel, '');
      expect(model.outcome, '');
    });
  });

  group('StudentRegistrationModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'campaignId': 5,
        'studentId': 10,
        'schoolUid': 'SCH001',
        'status': 'REGISTERED',
        'createdAt': '2026-06-01T10:00:00',
      };
      final model = StudentRegistrationModel.fromJson(json);
      expect(model.id, 1);
      expect(model.campaignId, 5);
      expect(model.studentId, 10);
      expect(model.schoolUid, 'SCH001');
      expect(model.status, 'REGISTERED');
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final model = StudentRegistrationModel.fromJson(json);
      expect(model.id, 0);
      expect(model.campaignId, 0);
      expect(model.studentId, 0);
      expect(model.schoolUid, '');
      expect(model.status, '');
    });
  });

  group('CampaignDashboardModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'totalEvents': 10,
        'totalTargetSchools': 50,
        'totalAssignedEmployees': 5,
        'totalInteractions': 200,
        'interactionsByOutcome': {'SUCCESSFUL': 100, 'FOLLOW_UP': 50, 'NO_RESPONSE': 50},
        'interactionsByProvince': [
          {'provinceName': 'Hà Nội', 'interactionCount': 50},
          {'provinceName': 'HCM', 'interactionCount': 100},
        ],
        'topSchools': [
          {'schoolName': 'THPT A', 'interactionCount': 20},
          {'schoolName': 'THPT B', 'interactionCount': 15},
        ],
      };
      final model = CampaignDashboardModel.fromJson(json);
      expect(model.totalEvents, 10);
      expect(model.totalTargetSchools, 50);
      expect(model.totalAssignedEmployees, 5);
      expect(model.totalInteractions, 200);
      expect(model.interactionsByOutcome['SUCCESSFUL'], 100);
      expect(model.interactionsByProvince.length, 2);
      expect(model.topSchools.length, 2);
    });

    test('fromJson handles empty lists', () {
      final json = {
        'totalEvents': 0,
        'totalTargetSchools': 0,
        'totalAssignedEmployees': 0,
        'totalInteractions': 0,
        'interactionsByOutcome': {},
        'interactionsByProvince': [],
        'topSchools': [],
      };
      final model = CampaignDashboardModel.fromJson(json);
      expect(model.totalEvents, 0);
      expect(model.interactionsByProvince, isEmpty);
      expect(model.topSchools, isEmpty);
    });
  });
}
