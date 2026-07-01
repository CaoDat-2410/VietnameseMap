import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:vietnamese_map/main.dart' as app;

// ignore_for_file: unawaited_futures
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow E2E', () {
    testWidgets('login page renders and login succeeds', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify login page elements
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Đăng nhập với Google'), findsOneWidget);

      // Enter credentials
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      await tester.enterText(emailField, 'staff@vn.edu.vn');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Tap login
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify home page loads
      expect(find.textContaining('Tổng quan'), findsWidgets);
    });
  });
}
