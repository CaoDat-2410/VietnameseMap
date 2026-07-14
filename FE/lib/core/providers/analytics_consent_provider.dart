import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/analytics_service.dart';

const _consentKey = 'analytics_consent';

/// Provider for analytics consent state.
///
/// Notifies [AnalyticsService] when consent changes so that all
/// subsequent [logEvent] calls are gated appropriately.
final analyticsConsentProvider =
    StateNotifierProvider<AnalyticsConsentNotifier, bool>((ref) {
  return AnalyticsConsentNotifier();
});

class AnalyticsConsentNotifier extends StateNotifier<bool> {
  AnalyticsConsentNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_consentKey) ?? true;
  }

  Future<void> setConsent(bool granted) async {
    state = granted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, granted);
    AnalyticsService.setConsent(granted);
  }
}
