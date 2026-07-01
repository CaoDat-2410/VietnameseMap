import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/core/widgets/bento_card.dart';
import 'package:vietnamese_map/core/theme/app_colors.dart';

void main() {
  group('BentoCard Widget Tests', () {
    testWidgets('renders child correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BentoCard(
              child: Text('Test Content'),
            ),
          ),
        ),
      );
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('responds to tap when onTap is provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BentoCard(
              onTap: () => tapped = true,
              child: Text('Tap Me'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BentoCard(
              padding: EdgeInsets.all(32),
              child: Text('Padded'),
            ),
          ),
        ),
      );
      final paddingWidget = tester.widget<Padding>(
        find.descendant(
          of: find.byType(BentoCard),
          matching: find.byType(Padding).first,
        ),
      );
      expect(paddingWidget.padding, EdgeInsets.all(32));
    });

    testWidgets('shows accent bar when showAccent is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BentoCard(
              showAccent: true,
              accentColor: Colors.red,
              child: Text('Accented'),
            ),
          ),
        ),
      );
      // Find Container with red decoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasRedContainer = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == Colors.red;
        }
        return false;
      });
      expect(hasRedContainer, isTrue);
    });

    testWidgets('uses correct size padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BentoCard(
              size: BentoSize.large,
              child: Text('Large'),
            ),
          ),
        ),
      );
      expect(find.text('Large'), findsOneWidget);
    });
  });

  group('KpiCard Widget Tests', () {
    testWidgets('displays title, value, and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KpiCard(
              title: 'Test Title',
              value: '42',
              icon: Icons.star,
            ),
          ),
        ),
      );
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('shows trend indicator when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KpiCard(
              title: 'Revenue',
              value: '\$1000',
              icon: Icons.money,
              trend: '+15%',
              trendUp: true,
            ),
          ),
        ),
      );
      expect(find.text('+15%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KpiCard(
              title: 'Users',
              value: '1000',
              icon: Icons.people,
              subtitle: 'Active users this month',
            ),
          ),
        ),
      );
      expect(find.text('Active users this month'), findsOneWidget);
    });

    testWidgets('responds to tap when onTap is provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KpiCard(
              title: 'Tappable',
              value: '42',
              icon: Icons.touch_app,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tappable'));
      expect(tapped, isTrue);
    });
  });

  group('StatusChip Widget Tests', () {
    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusChip(
              label: 'Active',
              status: StatusType.active,
            ),
          ),
        ),
      );
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows colored dot indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusChip(
              label: 'Status',
              status: StatusType.active,
            ),
          ),
        ),
      );
      // Find Container with dot color
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasCircularContainer = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.shape == BoxShape.circle;
        }
        return false;
      });
      expect(hasCircularContainer, isTrue);
    });

    testWidgets('all status types render correctly', (tester) async {
      for (final status in StatusType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusChip(
                label: status.name,
                status: status,
              ),
            ),
          ),
        );
        expect(find.text(status.name), findsOneWidget);
      }
    });
  });

  group('BentoGrid Widget Tests', () {
    testWidgets('renders children in grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BentoGrid(
              children: [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('uses custom gap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 500,
              child: BentoGrid(
                gap: 24,
                children: [
                  Text('Item 1'),
                  Text('Item 2'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(BentoGrid), findsOneWidget);
    });
  });
}
