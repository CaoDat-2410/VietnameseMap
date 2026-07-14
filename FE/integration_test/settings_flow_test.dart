import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:vietnamese_map/main.dart' as app;
import 'package:vietnamese_map/features/settings/presentation/pages/settings_page.dart';

// ignore_for_file: unawaited_futures
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Page Flow E2E', () {
    testWidgets('login → settings → analytics toggle → theme switch', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Login
      await tester.enterText(find.byType(TextField).first, 'staff@vn.edu.vn');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify settings page loaded
      expect(find.byType(SettingsPage), findsOneWidget);

      // Toggle analytics consent
      final switchTile = find.byType(SwitchListTile).first;
      await tester.tap(switchTile);
      await tester.pump(const Duration(milliseconds: 500));

      // Switch theme to dark
      await tester.tap(find.text('Tối'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify settings page still visible (no crash)
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });
}
