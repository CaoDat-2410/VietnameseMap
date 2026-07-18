import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/features/notifications/domain/models/notification_models.dart';
import 'package:vietnamese_map/features/notifications/presentation/pages/notification_center_page.dart';
import 'package:vietnamese_map/features/notifications/presentation/providers/notification_provider.dart';
import 'package:vietnamese_map/l10n/app_localizations.dart';

void main() {
  Widget appWith(List<NotificationItem> items) {
    return ProviderScope(
      overrides: [
        allNotificationsProvider.overrideWith((ref) async => items),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotificationCenterPage(),
      ),
    );
  }

  testWidgets('renders persisted notifications from the API provider',
      (tester) async {
    await tester.pumpWidget(appWith([
      NotificationItem(
        id: 15,
        title: 'FCM delivery verified',
        body: 'This notification came from notification_audit.',
        triggerType: 'ADMIN_MANUAL',
        status: 'SENT',
        createdAt: DateTime.now(),
      ),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('FCM delivery verified'), findsOneWidget);
    expect(
      find.text('This notification came from notification_audit.'),
      findsOneWidget,
    );
    expect(find.text('No notifications yet'), findsNothing);
  });

  testWidgets('shows a localized empty state when the API returns no items',
      (tester) async {
    await tester.pumpWidget(appWith(const []));
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
  });
}
