import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/features/notifications/presentation/notification_navigation.dart';

void main() {
  group('notificationDestination', () {
    test('opens the inbox for a general notification', () {
      expect(
        notificationDestination({'type': 'system_notice'}),
        '/notifications',
      );
    });

    test('opens an event when a valid event id is present', () {
      expect(
        notificationDestination({
          'type': 'today_event_reminder',
          'eventId': '26',
        }),
        '/events/26',
      );
    });

    test('opens student registrations for an approval result', () {
      expect(
        notificationDestination({
          'type': 'registration_approved',
          'campaignId': '10',
        }),
        '/student/my-registrations',
      );
    });

    test('does not build a route from a malformed id', () {
      expect(
        notificationDestination({
          'type': 'event_reminder',
          'eventId': 'not-a-number',
        }),
        '/notifications',
      );
    });
  });
}
