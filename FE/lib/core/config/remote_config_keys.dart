/// Keys for Remote Config flags defined in the Firebase Console.
class RemoteConfigKeys {
  RemoteConfigKeys._();

  static const googleSignInEnabled = 'google_signin_enabled';
  static const fcmEnabled = 'fcm_enabled';
  static const minAppVersion = 'min_app_version';
  static const showAnalyticsConsent = 'show_analytics_consent';
  static const maintenanceMode = 'maintenance_mode';
  static const maintenanceMessage = 'maintenance_message';
}

class RemoteConfigDefaults {
  RemoteConfigDefaults._();

  static const googleSignInEnabled = true;
  static const fcmEnabled = true;
  static const minAppVersion = '0.0.0';
  static const showAnalyticsConsent = false;
  static const maintenanceMode = false;
  static const maintenanceMessage =
      'Ứng dụng đang được bảo trì. Vui lòng quay lại sau.';
}

class RemoteConfigSnapshot {
  const RemoteConfigSnapshot(this._values);

  final Map<String, String?> _values;

  bool get googleSignInEnabled =>
      _values[RemoteConfigKeys.googleSignInEnabled]?.toBool() ??
      RemoteConfigDefaults.googleSignInEnabled;

  bool get fcmEnabled =>
      _values[RemoteConfigKeys.fcmEnabled]?.toBool() ??
      RemoteConfigDefaults.fcmEnabled;

  String get minAppVersion =>
      _values[RemoteConfigKeys.minAppVersion] ?? RemoteConfigDefaults.minAppVersion;

  bool get showAnalyticsConsent =>
      _values[RemoteConfigKeys.showAnalyticsConsent]?.toBool() ??
      RemoteConfigDefaults.showAnalyticsConsent;

  bool get maintenanceMode =>
      _values[RemoteConfigKeys.maintenanceMode]?.toBool() ??
      RemoteConfigDefaults.maintenanceMode;

  String get maintenanceMessage =>
      _values[RemoteConfigKeys.maintenanceMessage] ??
      RemoteConfigDefaults.maintenanceMessage;
}

extension on String {
  bool toBool() => toLowerCase() == 'true';
}
