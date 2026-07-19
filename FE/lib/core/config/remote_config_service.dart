import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'remote_config_keys.dart';

class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();

  FirebaseRemoteConfig? _rc;
  RemoteConfigSnapshot? _snapshot;

  bool get isInitialized => _snapshot != null;

  RemoteConfigSnapshot? get snapshot => _snapshot;

  Future<void> initialize() async {
    try {
      _rc = FirebaseRemoteConfig.instance;
      await _rc!.setDefaults(<String, dynamic>{
        RemoteConfigKeys.googleSignInEnabled: RemoteConfigDefaults.googleSignInEnabled,
        RemoteConfigKeys.fcmEnabled: RemoteConfigDefaults.fcmEnabled,
        RemoteConfigKeys.minAppVersion: RemoteConfigDefaults.minAppVersion,
        RemoteConfigKeys.showAnalyticsConsent: RemoteConfigDefaults.showAnalyticsConsent,
        RemoteConfigKeys.maintenanceMode: RemoteConfigDefaults.maintenanceMode,
        RemoteConfigKeys.maintenanceMessage: RemoteConfigDefaults.maintenanceMessage,
      });
      await _rc!.activate();
      _snapshot = _buildSnapshot();
      debugPrint(
          '[RemoteConfig] Initialized — maintenance=${_snapshot!.maintenanceMode}');
    } catch (e) {
      debugPrint('[RemoteConfig] Failed to initialize: $e — using defaults');
      _snapshot = const RemoteConfigSnapshot({});
    }
  }

  Future<bool> fetch() async {
    if (_rc == null) return false;
    try {
      final changed = await _rc!.fetchAndActivate();
      _snapshot = _buildSnapshot();
      debugPrint('[RemoteConfig] Fetch complete, changed=$changed');
      return changed;
    } catch (e) {
      debugPrint('[RemoteConfig] Fetch failed: $e');
      return false;
    }
  }

  RemoteConfigSnapshot _buildSnapshot() {
    if (_rc == null) return const RemoteConfigSnapshot({});
    return RemoteConfigSnapshot({
      RemoteConfigKeys.googleSignInEnabled: _rc!.getString(RemoteConfigKeys.googleSignInEnabled),
      RemoteConfigKeys.fcmEnabled: _rc!.getString(RemoteConfigKeys.fcmEnabled),
      RemoteConfigKeys.minAppVersion: _rc!.getString(RemoteConfigKeys.minAppVersion),
      RemoteConfigKeys.showAnalyticsConsent: _rc!.getString(RemoteConfigKeys.showAnalyticsConsent),
      RemoteConfigKeys.maintenanceMode: _rc!.getString(RemoteConfigKeys.maintenanceMode),
      RemoteConfigKeys.maintenanceMessage: _rc!.getString(RemoteConfigKeys.maintenanceMessage),
    });
  }
}
