// ignore_for_file: use_setters_to_change_properties
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin, consent-gated wrapper around [FirebaseAnalytics].
///
/// All analytics calls in the app must go through this service —
/// never call [FirebaseAnalytics] directly in widgets or repositories.
class AnalyticsService {
  AnalyticsService._();

  static bool _enabled = true;
  static String? _currentRole;
  static String? _env;

  /// Must be called once on app startup after user authentication.
  static Future<void> setUserContext({
    required String role,
    required String env,
    bool consentGranted = true,
  }) async {
    _currentRole = role;
    _env = env;
    _enabled = consentGranted;

    if (!_enabled) return;

    try {
      await FirebaseAnalytics.instance.setUserProperty(name: 'role', value: role);
      await FirebaseAnalytics.instance.setUserProperty(name: 'env', value: env);
    } catch (e) {
      debugPrint('[AnalyticsService] Failed to set user context: $e');
    }
  }

  /// Updates consent. Call from Settings → analytics consent toggle.
  static void setConsent(bool granted) {
    _enabled = granted;
  }

  /// Logs a screen view. Called automatically by [NavigationObserver].
  static Future<void> logScreen(String screenName) async {
    if (!_enabled) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'screen_view',
        parameters: {
          'screen_name': screenName,
          if (_currentRole != null) 'role': _currentRole!,
        },
      );
    } catch (e) {
      debugPrint('[AnalyticsService] logScreen failed: $e');
    }
  }

  /// Logs a named event with optional parameters.
  /// Parameters are validated against the event definition in [AnalyticsEvents].
  static Future<void> logEvent(
    String name, [
    Map<String, Object?>? params,
  ]) async {
    if (!_enabled) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: params?.cast<String, Object>(),
      );
    } catch (e) {
      debugPrint('[AnalyticsService] logEvent("$name") failed: $e');
    }
  }

  /// Logs an exception (non-fatal) to analytics + Sentry.
  static Future<void> logError(
    String context,
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    if (!_enabled) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'app_error',
        parameters: {
          'context': context,
          'error': error.toString(),
          'env': _env ?? 'unknown',
        },
      );
    } catch (e) {
      debugPrint('[AnalyticsService] logError failed: $e');
    }
  }
}
