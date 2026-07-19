import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:vietnamese_map/main.dart' as app;

// ignore_for_file: unawaited_futures
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Campaign List Flow E2E', () {
    testWidgets('login → campaigns page → campaign list', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Login
      await tester.enterText(find.byType(TextField).first, 'staff@vn.edu.vn');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to campaigns via sidebar icon
      final campaignIcon = find.byIcon(Icons.campaign);
      if (campaignIcon.evaluate().isNotEmpty) {
        await tester.tap(campaignIcon.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify campaign list content
        expect(find.textContaining('Chiến dịch'), findsWidgets);
      }
    });
  });
}
