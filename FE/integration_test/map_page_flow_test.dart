import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:vietnamese_map/main.dart' as app;
import 'package:vietnamese_map/features/map/presentation/pages/map_page.dart';

// ignore_for_file: unawaited_futures
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Map Page Flow E2E', () {
    testWidgets('login → map page renders', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Login
      await tester.enterText(find.byType(TextField).first, 'staff@vn.edu.vn');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify map widget is present
      expect(find.byType(MapPage), findsOneWidget);
    });
  });
}
