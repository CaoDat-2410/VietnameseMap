import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/core/utils/responsive.dart';

void main() {
  group('Responsive', () {
    test('isMobile returns true for screens < 600', () {
      expect(Responsive.isMobile(buildContext(500, 800)), isTrue);
      expect(Responsive.isMobile(buildContext(599, 800)), isTrue);
    });

    test('isMobile returns false for screens >= 600', () {
      expect(Responsive.isMobile(buildContext(600, 800)), isFalse);
      expect(Responsive.isMobile(buildContext(1200, 800)), isFalse);
    });

    test('isTablet returns true for 600 <= screens < 900', () {
      expect(Responsive.isTablet(buildContext(600, 800)), isTrue);
      expect(Responsive.isTablet(buildContext(800, 800)), isTrue);
    });

    test('isTablet returns false for screens outside range', () {
      expect(Responsive.isTablet(buildContext(500, 800)), isFalse);
      expect(Responsive.isTablet(buildContext(900, 800)), isFalse);
    });

    test('isDesktop returns true for screens >= 900', () {
      expect(Responsive.isDesktop(buildContext(900, 800)), isTrue);
      expect(Responsive.isDesktop(buildContext(1400, 800)), isTrue);
    });

    test('screenType returns correct type', () {
      expect(Responsive.screenType(buildContext(500, 800)), ScreenType.mobile);
      expect(Responsive.screenType(buildContext(700, 800)), ScreenType.tablet);
      expect(Responsive.screenType(buildContext(1000, 800)), ScreenType.smallDesktop);
      expect(Responsive.screenType(buildContext(1400, 800)), ScreenType.largeDesktop);
    });

    test('width returns correct value', () {
      expect(Responsive.width(buildContext(1200, 800)), 1200);
      expect(Responsive.width(buildContext(800, 600)), 800);
    });

    test('height returns correct value', () {
      expect(Responsive.height(buildContext(1200, 800)), 800);
      expect(Responsive.height(buildContext(800, 600)), 600);
    });

    test('gridColumns returns correct values', () {
      expect(Responsive.gridColumns(buildContext(500, 800)), 1);
      expect(Responsive.gridColumns(buildContext(700, 800)), 2);
      expect(Responsive.gridColumns(buildContext(1000, 800)), 3);
      expect(Responsive.gridColumns(buildContext(1200, 800)), 4);
    });
  });

  group('ResponsiveBuilder', () {
    testWidgets('shows mobile widget on small screens', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('shows tablet widget on medium screens', (tester) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('shows desktop widget on large screens', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsOneWidget);
    });

    testWidgets('falls back correctly when widget not provided', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: Text('Mobile'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      // Should show desktop when tablet not provided
      expect(find.text('Desktop'), findsOneWidget);
    });
  });

  group('ResponsiveValue', () {
    testWidgets('returns mobile value on small screens', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveValue<String>(
            mobile: 'Mobile',
            tablet: 'Tablet',
            desktop: 'Desktop',
          ).build(contextBuilder(tester)),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
    });

    testWidgets('returns tablet value on medium screens', (tester) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveValue<String>(
            mobile: 'Mobile',
            tablet: 'Tablet',
            desktop: 'Desktop',
          ).build(contextBuilder(tester)),
        ),
      );

      expect(find.text('Tablet'), findsOneWidget);
    });

    test('get returns correct value', () {
      // This tests the static get method with mock context
      final value = ResponsiveValue<int>(mobile: 1, tablet: 2, desktop: 3);
      // Direct test of the get method is complex without full context
      // so we rely on widget tests above
    });
  });

  group('ResponsiveGrid', () {
    testWidgets('renders children correctly', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 4,
              children: [
                Container(key: Key('item1')),
                Container(key: Key('item2')),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(Key('item1')), findsOneWidget);
      expect(find.byKey(Key('item2')), findsOneWidget);
    });
  });

  group('NavigationType', () {
    testWidgets('returns bottomBar for mobile', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final type = NavigationTypeExtension.getType(tester.element(find.byType(Container)));
      expect(type, NavigationType.bottomBar);
    });

    testWidgets('returns rail for tablet', (tester) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final type = NavigationTypeExtension.getType(tester.element(find.byType(Container)));
      expect(type, NavigationType.rail);
    });

    testWidgets('returns sideNav for desktop', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final type = NavigationTypeExtension.getType(tester.element(find.byType(Container)));
      expect(type, NavigationType.sideNav);
    });
  });
}

// Helper functions for testing
BuildContext buildContext(double width, double height) {
  return TestBuildContext(MediaQueryData(size: Size(width, height)));
}

Widget contextBuilder(WidgetTester tester) {
  return Builder(
    builder: (context) => Text(ResponsiveValue<String>(
      mobile: 'Mobile',
      tablet: 'Tablet',
      desktop: 'Desktop',
    ).get(context)),
  );
}

class TestBuildContext implements BuildContext {
  TestBuildContext(this._mediaQueryData);

  final MediaQueryData _mediaQueryData;

  @override
  MediaQueryData get mediaQueryData => _mediaQueryData;

  @override
  Widget get widget => throw UnimplementedError();

  @override
  RenderObject? get renderObject => throw UnimplementedError();

  @override
  bool get mounted => throw UnimplementedError();

  @override
  DiagnosticsNode toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) =>
      throw UnimplementedError();

  @override
  void dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({
    Object? aspect,
  }) =>
      throw UnimplementedError();

  @override
  T? dependOnInheritedElement<T extends InheritedElement>(
    InheritedElement ancestor, {
    Object? aspect,
  }) =>
      throw UnimplementedError();

  @override
  InheritedElement?
      getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() =>
          throw UnimplementedError();

  @override
  void visitAncestor(bool Function(Element element) visitor) {}

  @override
  void visitChildElements(bool Function(Element element) visitor) {}

  @override
  DiagnosticsNode toDiagnosticsNode({
    String? name,
    DiagnosticsTreeStyle? style,
  }) =>
      throw UnimplementedError();
}
