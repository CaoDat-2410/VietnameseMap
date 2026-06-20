import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/features/campaign/presentation/widgets/create_interaction_dialog.dart';
import 'package:vietnamese_map/features/school/shared/models/school_model.dart';

void main() {
  const school = SchoolModel(
    schoolUid: '01-001',
    provinceCode: '01',
    provinceName: 'Hà Nội',
    communeCode: '00001',
    communeName: 'Ba Đình',
    schoolCode: '001',
    schoolName: 'Trường THPT Demo',
    address: 'Hà Nội',
    areaType: 'KV3',
  );

  testWidgets('does not ask users to type a school UID', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CreateInteractionDialog())),
    );

    expect(find.text('School UID'), findsNothing);
    expect(find.text('Enter a school UID'), findsNothing);
    expect(find.text('Search and select a school'), findsOneWidget);
  });

  testWidgets('uses the selected school model UID in the request body', (
    tester,
  ) async {
    Map<String, dynamic>? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (_) => const CreateInteractionDialog(
                    availableSchools: [school],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Trường THPT Demo'), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(result?['schoolUid'], '01-001');
    expect(result?['nextFollowUpAt'], isNull);
  });
}
