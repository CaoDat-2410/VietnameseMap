import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/core/utils/responsive.dart';

void main() {
  Future<BuildContext> contextAt(WidgetTester tester, double width) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: const Scaffold(body: Text('responsive-context')),
      ),
    ));
    return tester.element(find.text('responsive-context'));
  }

  group('Responsive breakpoints', () {
    testWidgets('classifies mobile, tablet, small desktop, and large desktop', (tester) async {
      expect(Responsive.screenType(await contextAt(tester, 500)), ScreenType.mobile);
      expect(Responsive.screenType(await contextAt(tester, 700)), ScreenType.tablet);
      expect(Responsive.screenType(await contextAt(tester, 1000)), ScreenType.smallDesktop);
      expect(Responsive.screenType(await contextAt(tester, 1400)), ScreenType.largeDesktop);
    });

    testWidgets('returns responsive grid columns and padding', (tester) async {
      expect(Responsive.gridColumns(await contextAt(tester, 500)), 1);
      expect(Responsive.gridColumns(await contextAt(tester, 700)), 2);
      expect(Responsive.gridColumns(await contextAt(tester, 1000)), 3);
      expect(Responsive.gridColumns(await contextAt(tester, 1400)), 4);
    });

    testWidgets('selects the expected navigation type', (tester) async {
      expect(NavigationTypeExtension.getType(await contextAt(tester, 500)), NavigationType.bottomBar);
      expect(NavigationTypeExtension.getType(await contextAt(tester, 700)), NavigationType.rail);
      expect(NavigationTypeExtension.getType(await contextAt(tester, 1000)), NavigationType.sideNav);
    });
  });

  group('Responsive widgets', () {
    testWidgets('ResponsiveBuilder selects the matching child', (tester) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(const MaterialApp(home: ResponsiveBuilder(
        mobile: Text('mobile'), tablet: Text('tablet'), desktop: Text('desktop'),
      )));
      expect(find.text('tablet'), findsOneWidget);
      expect(find.text('mobile'), findsNothing);
    });

    testWidgets('ResponsiveValue selects the matching value', (tester) async {
      final context = await contextAt(tester, 1000);
      expect(const ResponsiveValue<String>(mobile: 'm', tablet: 't', desktop: 'd').get(context), 'd');
    });

    testWidgets('ResponsiveGrid renders all children', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox(
        width: 500,
        child: ResponsiveGrid(children: [Text('one'), Text('two')]),
      )));
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
    });
  });
}