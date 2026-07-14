import 'package:flutter/material.dart';

import '../analytics/analytics_service.dart';

/// A [RouterObserver] that logs [screen_view] analytics events on every
/// navigation.
///
/// Wire this into [GoRouter] via:
///
/// ```dart
/// final router = GoRouter(
///   observers: [AnalyticsNavigationObserver()],
///   // ...
/// );
/// ```
class AnalyticsNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _logScreenView(newRoute);
  }

  void _logScreenView(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null) {
      AnalyticsService.logScreen(name);
    }
  }
}
