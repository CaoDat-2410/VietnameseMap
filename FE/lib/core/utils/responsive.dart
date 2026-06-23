import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Responsive breakpoints and helpers
class Responsive {
  Responsive._();

  /// Mobile breakpoint (< 600)
  static const double mobile = AppSpacing.breakpointMobile;

  /// Tablet breakpoint (600 - 899)
  static const double tablet = AppSpacing.breakpointTablet;

  /// Desktop breakpoint (900 - 1199)
  static const double desktop = AppSpacing.breakpointDesktop;

  /// Large desktop (>= 1200)
  static const double largeDesktop = 1400;

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  /// Check if current screen is large desktop
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= largeDesktop;

  /// Get current screen type
  static ScreenType screenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return ScreenType.mobile;
    if (width < tablet) return ScreenType.tablet;
    if (width < desktop) return ScreenType.smallDesktop;
    return ScreenType.largeDesktop;
  }

  /// Get screen width
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height
  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Get padding based on screen size
  static EdgeInsets screenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(AppSpacing.screenPaddingMobile);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(AppSpacing.screenPaddingTablet);
    } else {
      return const EdgeInsets.all(AppSpacing.screenPaddingDesktop);
    }
  }

  /// Get grid columns based on screen size
  static int gridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    if (width(context) < desktop) return 3;
    return 4;
  }
}

/// Screen types
enum ScreenType {
  mobile,
  tablet,
  smallDesktop,
  largeDesktop,
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.largeDesktop) {
          return largeDesktop ?? desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= Responsive.tablet) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= Responsive.mobile) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// Responsive grid
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.largeDesktopColumns = 4,
    this.gap = AppSpacing.base,
    this.runGap,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int largeDesktopColumns;
  final double gap;
  final double? runGap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _getColumns(constraints.maxWidth);
        final actualRunGap = runGap ?? gap;

        return Wrap(
          spacing: gap,
          runSpacing: actualRunGap,
          children: children.map((child) {
            final availableWidth =
                (constraints.maxWidth - (gap * (columns - 1))) / columns;
            return SizedBox(
              width: availableWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }

  int _getColumns(double width) {
    if (width >= Responsive.largeDesktop) return largeDesktopColumns;
    if (width >= Responsive.tablet) return desktopColumns;
    if (width >= Responsive.mobile) return tabletColumns;
    return mobileColumns;
  }
}

/// Responsive value helper
class ResponsiveValue<T> {
  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? largeDesktop;

  T get(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Responsive.largeDesktop) {
      return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
    if (width >= Responsive.tablet) {
      return desktop ?? tablet ?? mobile;
    }
    if (width >= Responsive.mobile) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

/// Navigation type based on screen size
enum NavigationType {
  bottomBar,
  rail,
  sideNav,
}

extension NavigationTypeExtension on NavigationType {
  static NavigationType getType(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return NavigationType.bottomBar;
    }
    if (Responsive.isTablet(context)) {
      return NavigationType.rail;
    }
    return NavigationType.sideNav;
  }
}
